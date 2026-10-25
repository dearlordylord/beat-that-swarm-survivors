use crate::{ALPN, MAX_MESSAGE, invitation, parse_invitation};
use iroh::{
    Endpoint, RelayMode, RelayUrl,
    endpoint::{Connection, presets},
};
use js_sys::{Function, Object, Reflect, Uint8Array};
use n0_future::time::{Duration, timeout};
use std::{cell::RefCell, rc::Rc};
use wasm_bindgen::prelude::*;
use wasm_bindgen_futures::spawn_local;

const MAX_IN_FLIGHT: usize = 16;
const TIMEOUT: Duration = Duration::from_secs(20);
const RELAY_URL: &str = "https://quint-graph.fly.dev";

struct Inner {
    endpoint: Endpoint,
    callback: Function,
    connection: Option<Connection>,
    generation: u32,
    pending: bool,
    closed: bool,
    sends: usize,
}

type Shared = Rc<RefCell<Inner>>;

fn failure(message: impl ToString) -> JsValue {
    js_sys::Error::new(&message.to_string()).into()
}

fn emit(
    shared: &Shared,
    kind: &str,
    peer: Option<&str>,
    message: Option<&str>,
    bytes: Option<&[u8]>,
) {
    // Never invoke JavaScript while holding a RefCell borrow: callbacks may close us.
    let callback = shared.borrow().callback.clone();
    let event = Object::new();
    Reflect::set(&event, &"type".into(), &kind.into()).ok();
    Reflect::set(&event, &"path".into(), &"relay".into()).ok();
    Reflect::set(&event, &"relayUrl".into(), &RELAY_URL.into()).ok();
    if let Some(peer) = peer {
        Reflect::set(&event, &"peerId".into(), &peer.into()).ok();
    }
    if let Some(message) = message {
        Reflect::set(&event, &"message".into(), &message.into()).ok();
    }
    if let Some(bytes) = bytes {
        Reflect::set(&event, &"bytes".into(), &Uint8Array::from(bytes)).ok();
    }
    callback.call1(&JsValue::NULL, &event).ok();
}

fn current(shared: &Shared, generation: u32) -> bool {
    let inner = shared.borrow();
    !inner.closed && inner.generation == generation
}

fn install(shared: &Shared, connection: Connection) -> Result<(), JsValue> {
    let generation = {
        let mut inner = shared.borrow_mut();
        if inner.closed || inner.connection.is_some() {
            connection.close(1u32.into(), b"Endpoint already has a peer or is closed");
            return Err(failure("This endpoint already has a peer"));
        }
        inner.pending = false;
        inner.generation = inner.generation.wrapping_add(1);
        inner.connection = Some(connection.clone());
        inner.generation
    };
    let peer = connection.remote_id().to_string();
    emit(shared, "connected", Some(&peer), None, None);
    let shared = shared.clone();
    spawn_local(async move {
        let error = loop {
            let mut stream = match connection.accept_uni().await {
                Ok(stream) => stream,
                Err(error) => break error.to_string(),
            };
            let bytes = match timeout(TIMEOUT, stream.read_to_end(MAX_MESSAGE)).await {
                Ok(Ok(bytes)) => bytes,
                Ok(Err(error)) => {
                    connection.close(2u32.into(), b"Invalid or oversized transport frame");
                    break error.to_string();
                }
                Err(_) => {
                    connection.close(3u32.into(), b"Transport frame timed out");
                    break "Incoming frame timed out".into();
                }
            };
            if !current(&shared, generation) {
                return;
            }
            emit(&shared, "message", Some(&peer), None, Some(&bytes));
        };
        if current(&shared, generation) {
            {
                let mut inner = shared.borrow_mut();
                inner.connection = None;
                inner.pending = false;
            }
            emit(&shared, "disconnected", Some(&peer), Some(&error), None);
        }
    });
    Ok(())
}

/// A single-peer endpoint. Each send is one reliable QUIC unidirectional stream,
/// bounded to 1048576 bytes. Browser Iroh is relay-only; this is not a direct-path probe.
#[wasm_bindgen]
pub struct Transport {
    inner: Shared,
}

#[wasm_bindgen]
impl Transport {
    #[wasm_bindgen(js_name = create)]
    pub async fn create(callback: Function) -> Result<Transport, JsValue> {
        console_error_panic_hook::set_once();
        let relay: RelayUrl = RELAY_URL.parse().map_err(failure)?;
        let endpoint = timeout(
            TIMEOUT,
            Endpoint::builder(presets::N0)
                .relay_mode(RelayMode::Custom([relay].into_iter().collect()))
                .alpns(vec![ALPN.to_vec()])
                .bind(),
        )
        .await
        .map_err(|_| failure("Endpoint creation timed out"))?
        .map_err(failure)?;
        if timeout(TIMEOUT, endpoint.online()).await.is_err() {
            endpoint.close().await;
            return Err(failure("No Iroh relay became available within 20 seconds"));
        }
        let inner = Rc::new(RefCell::new(Inner {
            endpoint: endpoint.clone(),
            callback,
            connection: None,
            generation: 0,
            pending: false,
            closed: false,
            sends: 0,
        }));
        let accept_shared = inner.clone();
        spawn_local(async move {
            while let Some(incoming) = endpoint.accept().await {
                let available = {
                    let i = accept_shared.borrow();
                    !i.closed && !i.pending && i.connection.is_none()
                };
                if !available {
                    incoming.refuse();
                    continue;
                }
                let generation = {
                    let mut inner = accept_shared.borrow_mut();
                    inner.pending = true;
                    inner.generation
                };
                match timeout(TIMEOUT, incoming).await {
                    Ok(Ok(connection)) => {
                        if !current(&accept_shared, generation) {
                            connection.close(0u32.into(), b"Endpoint closed while accepting");
                            continue;
                        }
                        if let Err(error) = install(&accept_shared, connection) {
                            emit(
                                &accept_shared,
                                "error",
                                None,
                                Some(&format!("{error:?}")),
                                None,
                            );
                        }
                    }
                    result => {
                        accept_shared.borrow_mut().pending = false;
                        if !accept_shared.borrow().closed {
                            emit(
                                &accept_shared,
                                "error",
                                None,
                                Some(&format!("Incoming connection failed: {result:?}")),
                                None,
                            );
                        }
                    }
                }
            }
        });
        let me = inner.borrow().endpoint.id().to_string();
        emit(&inner, "ready", Some(&me), None, None);
        Ok(Self { inner })
    }

    #[wasm_bindgen(js_name = endpointId)]
    pub fn endpoint_id(&self) -> String {
        self.inner.borrow().endpoint.id().to_string()
    }

    pub fn invitation(&self) -> Result<String, JsValue> {
        if self.inner.borrow().closed {
            return Err(failure("Endpoint is closed"));
        }
        invitation(&self.inner.borrow().endpoint.addr()).map_err(failure)
    }

    pub async fn join(&self, invite: String) -> Result<(), JsValue> {
        let addr = parse_invitation(&invite).map_err(failure)?;
        let (endpoint, generation) = {
            let mut inner = self.inner.borrow_mut();
            if inner.closed || inner.pending || inner.connection.is_some() {
                return Err(failure(
                    "Endpoint is closed, connecting or already connected",
                ));
            }
            if addr.id == inner.endpoint.id() {
                return Err(failure("An endpoint cannot join itself"));
            }
            inner.pending = true;
            inner.generation = inner.generation.wrapping_add(1);
            (inner.endpoint.clone(), inner.generation)
        };
        emit(
            &self.inner,
            "connecting",
            Some(&addr.id.to_string()),
            None,
            None,
        );
        let result = timeout(TIMEOUT, endpoint.connect(addr, ALPN)).await;
        if !current(&self.inner, generation) {
            if let Ok(Ok(connection)) = result {
                connection.close(0u32.into(), b"Endpoint closed while connecting");
            }
            return Err(failure("Connection attempt was cancelled"));
        }
        self.inner.borrow_mut().pending = false;
        let connection = result
            .map_err(|_| failure("Connection timed out"))?
            .map_err(failure)?;
        install(&self.inner, connection)
    }

    pub async fn send(&self, bytes: Vec<u8>) -> Result<(), JsValue> {
        if bytes.len() > MAX_MESSAGE {
            return Err(failure("Transport payload exceeds 1048576 bytes"));
        }
        let (connection, generation) = {
            let mut inner = self.inner.borrow_mut();
            if inner.closed {
                return Err(failure("Endpoint is closed"));
            }
            if inner.sends >= MAX_IN_FLIGHT {
                return Err(failure("Transport send queue is full"));
            }
            let connection = inner
                .connection
                .clone()
                .ok_or_else(|| failure("No peer is connected"))?;
            inner.sends += 1;
            (connection, inner.generation)
        };
        let result = timeout(TIMEOUT, async {
            let mut stream = connection.open_uni().await.map_err(failure)?;
            stream.write_all(&bytes).await.map_err(failure)?;
            stream.finish().map_err(failure)?;
            Ok::<(), JsValue>(())
        })
        .await;
        {
            let mut inner = self.inner.borrow_mut();
            inner.sends = inner.sends.saturating_sub(1);
        }
        if !current(&self.inner, generation) {
            return Err(failure("Connection changed while sending"));
        }
        result.map_err(|_| failure("Transport send timed out"))?
    }

    pub fn close(&self) {
        let (endpoint, connection, already_closed) = {
            let mut inner = self.inner.borrow_mut();
            let previous = inner.closed;
            inner.closed = true;
            inner.pending = false;
            inner.generation = inner.generation.wrapping_add(1);
            (inner.endpoint.clone(), inner.connection.take(), previous)
        };
        if already_closed {
            return;
        }
        if let Some(connection) = connection {
            connection.close(0u32.into(), b"User disconnected");
        }
        emit(&self.inner, "closed", None, None, None);
        spawn_local(async move {
            endpoint.close().await;
        });
    }
}

impl Drop for Transport {
    fn drop(&mut self) {
        self.close();
    }
}
