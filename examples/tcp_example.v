module main

import jsonrpc
import net
import time

fn send_error_tcp(err_code int, conn net.Socket) {
	mut eres := jsonrpc.Response{}
	eres.send_error(err_code)
	send_tcp_resp(&eres, conn)
}

fn handle_tcp(srv jsonrpc.Server, conn net.Socket) {
	s := conn.read_line()
	defer {	conn.close() or { } }

	res := srv.exec(s) or {
		err_code := err.int()
		send_error_tcp(err_code, conn)
		return
	}

	conn.send_string(res.gen_resp_text()) or { }
}

fn send_tcp_resp(resp &jsonrpc.Response, conn net.Socket) {
	s := resp.gen_resp_text()
	conn.send_string(s)
}

fn send_req(port_num int) {
	println('start send req...')
	client := net.dial('127.0.0.1', port_num) or {	panic(err) }
	println('done')
	req := jsonrpc.Request{method:'greet', id:1}
	s := req.gen_req_text()
	println(s)
	client.send_string(s)
}

fn main() {
    port_num := 8000
	server := net.listen(port_num) or { panic('Failed to listen to port ${port_num}') }
	println('JSON-RPC Server has started on port ${port_num}')
    mut srv := jsonrpc.new()

    srv.register('greet', fn (mut ctx jsonrpc.Context) string {
        name := jsonrpc.as_string(ctx.req.params)
        return 'Hello, $name'
    })

	for {
		conn := server.accept() or {
			// send_error_tcp(server_error_start, conn)
			// server.close() or { }
			panic(err)
		}

		go handle_tcp(srv, conn)
	}
}