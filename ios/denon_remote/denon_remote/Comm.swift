//
//  Comm.swift
//  denon_remote
//
//  Created by Alex Fadeev on 2021-04-30.
//

import Foundation
import Darwin

func htons(value: CUnsignedShort) -> CUnsignedShort {
    return (value << 8) + (value >> 8);
}

func udpSendString(textToSend: String, address: String, port: CUnsignedShort) {

    var adr = in_addr()
    inet_pton(AF_INET, address, &adr)

    let fd = socket(AF_INET, SOCK_DGRAM, 0) // UDP

    let addr = sockaddr_in(
        sin_len:    __uint8_t(MemoryLayout<sockaddr_in>.size),
        sin_family: sa_family_t(AF_INET),
        sin_port:   htons(value: port),
        sin_addr:   adr, //address, =>>> addr=6502a8c0  65 02  a8  c0 <- eto 192.168.2.101
                         //                            101  2 168 192
        sin_zero:   (0, 0, 0, 0, 0, 0, 0, 0)
    )

    let sent = textToSend.withCString {cstr -> Int in

        var localCopy = addr

        let sent = withUnsafePointer(to: &localCopy) { pointer -> Int in
            let memory = UnsafeRawPointer(pointer).bindMemory(to: sockaddr.self, capacity: 1)
            let sent = sendto(fd, cstr, strlen(cstr), 0, memory, socklen_t(addr.sin_len))
            return sent
        }

        return sent
    }

    close(fd)
}

// to convert String -> Bytes use: "string".bytes
extension StringProtocol {
    var data: Data { .init(utf8) }
    var bytes: [UInt8] { .init(utf8) }
}

func udpSendBytes(payload: ContiguousBytes, address: String, port: CUnsignedShort) {
//func udpSendBytes(payload: ContiguousBytes = "23".bytes, address: String, port: CUnsignedShort) {
    var adr = in_addr()
    inet_pton(AF_INET, address, &adr)

    let fd = socket(AF_INET, SOCK_DGRAM, 0)
    
    let addr = sockaddr_in(
        sin_len:    __uint8_t(MemoryLayout<sockaddr_in>.size),
        sin_family: sa_family_t(AF_INET),
        sin_port:   htons(value: port),
        sin_addr:   adr,
        sin_zero:   (0, 0, 0, 0, 0, 0, 0, 0)
    )
    
    //sendto(fd, payload.withCString(), strlen(payload), 0, addr.sin_addr, socklen_t(addr.sin_len))
    
}
