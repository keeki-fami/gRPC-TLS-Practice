use tonic::{transport::Server, Request, Response, Status};
use tonic::transport::{server::ServerTlsConfig, Identity};

use echo::echo_server::{Echo, EchoServer};
use echo::{EchoRequest, EchoResponse};

// echoを公開 → echo, echoserverなど
pub mod echo {
    tonic::include_proto!("echo");
}

#[derive(Debug, Default)]
pub struct MyEcho {}

#[tonic::async_trait]
impl Echo for MyEcho {
    async fn do_echo(
        &self,
        request: Request<EchoRequest>,
    ) -> Result<Response<EchoResponse>, Status> {
        println!("got a request: {:?}", request);

        let reply = EchoResponse {
            text: request.into_inner().text,
        };

        Ok(Response::new(reply))
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr = "127.0.0.1:50051".parse()?;
    let echo = MyEcho::default();

    let key: Vec<u8> = tokio::fs::read("./cert/server.key.pem").await?;
    let cert: Vec<u8> = tokio::fs::read("./cert/server.pem").await?;

    let key_str = String::from_utf8(key).unwrap();
    let cert_str = String::from_utf8(cert).unwrap();

    let identity = Identity::from_pem(cert_str, key_str);



    println!("port: 50051");

    Server::builder()
        .tls_config(ServerTlsConfig::new().identity(identity)).unwrap()
        .add_service(EchoServer::new(echo))
        .serve(addr)
        .await?;

    Ok(())
}
