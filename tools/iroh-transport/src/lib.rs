//! Byte-only Iroh transport. Application protocol decisions live outside this crate.
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use iroh::EndpointAddr;

pub const ALPN: &[u8] = b"bendvy-transport-prototype/1";
pub const MAX_MESSAGE: usize = 1024 * 1024;
const INVITATION_PREFIX: &str = "bendvy-iroh-v1:";

pub fn invitation(addr: &EndpointAddr) -> Result<String, String> {
    let bytes = serde_json::to_vec(addr).map_err(|e| e.to_string())?;
    Ok(format!(
        "{INVITATION_PREFIX}{}",
        URL_SAFE_NO_PAD.encode(bytes)
    ))
}

pub fn parse_invitation(text: &str) -> Result<EndpointAddr, String> {
    let encoded = text
        .trim()
        .strip_prefix(INVITATION_PREFIX)
        .ok_or("This is not a Bendvy Iroh invitation")?;
    if encoded.len() > 8192 {
        return Err("Invitation is too large".into());
    }
    let bytes = URL_SAFE_NO_PAD
        .decode(encoded)
        .map_err(|_| "Invitation encoding is invalid")?;
    let addr: EndpointAddr =
        serde_json::from_slice(&bytes).map_err(|_| "Invitation address is invalid")?;
    if addr.addrs.is_empty() {
        return Err("Invitation has no relay or direct address".into());
    }
    Ok(addr)
}

#[cfg(target_arch = "wasm32")]
mod browser;
#[cfg(target_arch = "wasm32")]
pub use browser::Transport;

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn rejects_non_invitation_and_oversized_input() {
        assert!(parse_invitation("not-an-invitation").is_err());
        assert!(parse_invitation(&format!("{INVITATION_PREFIX}{}", "x".repeat(8193))).is_err());
    }
}

#[cfg(all(test, feature = "native-probe", not(target_arch = "wasm32")))]
mod native_tests {
    use super::*;
    use iroh::{Endpoint, endpoint::presets};
    use std::{net::SocketAddr, time::Duration};

    #[tokio::test]
    async fn ordered_burst_waits_for_delayed_lower_stream_and_rejects_oversize() {
        tokio::time::timeout(Duration::from_secs(15), async {
            let address: SocketAddr = "127.0.0.1:0".parse().unwrap();
            let host = Endpoint::builder(presets::Minimal)
                .alpns(vec![ALPN.to_vec()])
                .bind_addr(address)
                .unwrap()
                .bind()
                .await
                .unwrap();
            let guest = Endpoint::builder(presets::Minimal)
                .alpns(vec![ALPN.to_vec()])
                .bind_addr(address)
                .unwrap()
                .bind()
                .await
                .unwrap();
            let addr = EndpointAddr::new(host.id()).with_ip_addr(host.bound_sockets()[0]);
            let encoded = invitation(&addr).unwrap();
            assert_eq!(parse_invitation(&encoded).unwrap(), addr);
            let (outgoing, incoming) = tokio::join!(guest.connect(addr, ALPN), async {
                host.accept().await.unwrap().await
            });
            let outgoing = outgoing.unwrap();
            let incoming = incoming.unwrap();
            let receiver = tokio::spawn(async move {
                let mut received = Vec::new();
                for _ in 0..50 {
                    let mut stream = incoming.accept_uni().await.unwrap();
                    received.push(stream.read_to_end(MAX_MESSAGE).await.unwrap());
                }
                let mut boundary = incoming.accept_uni().await.unwrap();
                assert_eq!(boundary.read_to_end(MAX_MESSAGE).await.unwrap(), vec![7; MAX_MESSAGE]);
                let mut too_large = incoming.accept_uni().await.unwrap();
                assert!(too_large.read_to_end(MAX_MESSAGE).await.is_err());
                received
            });
            let mut delayed = outgoing.open_uni().await.unwrap();
            for i in 1u32..50 {
                let mut stream = outgoing.open_uni().await.unwrap();
                stream.write_all(&i.to_be_bytes()).await.unwrap();
                stream.finish().unwrap();
            }
            tokio::time::sleep(Duration::from_millis(100)).await;
            delayed.write_all(&0u32.to_be_bytes()).await.unwrap();
            delayed.finish().unwrap();
            let mut boundary = outgoing.open_uni().await.unwrap();
            boundary.write_all(&vec![7; MAX_MESSAGE]).await.unwrap();
            boundary.finish().unwrap();
            let mut oversized = outgoing.open_uni().await.unwrap();
            oversized
                .write_all(&vec![0; MAX_MESSAGE + 1])
                .await
                .unwrap();
            oversized.finish().unwrap();
            let received = receiver.await.unwrap();
            assert_eq!(
                received,
                (0u32..50)
                    .map(|i| i.to_be_bytes().to_vec())
                    .collect::<Vec<_>>()
            );
            guest.close().await;
            host.close().await;
        })
        .await
        .expect("Native loopback protocol probe timed out");
    }
}
