//! Transport-only peer for browser/native interoperability. It does not interpret Bend packets.
use bendvy_iroh_transport::{ALPN, MAX_MESSAGE, invitation, parse_invitation};
use iroh::{Endpoint, endpoint::presets};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let endpoint = Endpoint::builder(presets::N0)
        .alpns(vec![ALPN.to_vec()])
        .bind()
        .await?;
    tokio::time::timeout(std::time::Duration::from_secs(30), endpoint.online()).await?;
    println!("{}", invitation(&endpoint.addr())?);
    let connection = if let Some(invite) = std::env::args().nth(1) {
        endpoint.connect(parse_invitation(&invite)?, ALPN).await?
    } else {
        endpoint.accept().await.ok_or("Endpoint closed")?.await?
    };
    println!("CONNECTED {}", connection.remote_id());
    println!("PATHS {:?}", connection.paths());
    loop {
        let mut incoming = match connection.accept_uni().await {
            Ok(stream) => stream,
            Err(_) => break,
        };
        let bytes = incoming.read_to_end(MAX_MESSAGE).await?;
        let mut outgoing = connection.open_uni().await?;
        outgoing.write_all(&bytes).await?;
        outgoing.finish()?;
        println!("ECHO {} bytes", bytes.len());
    }
    endpoint.close().await;
    Ok(())
}
