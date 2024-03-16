/*
 SwiftyGPIO

 Copyright (c) 2017 Umberto Raimondi
 Licensed under the MIT license, as follows:

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.)
 */
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

extension SwiftyGPIO {

    public static func hardwareI2Cs(for board: SupportedBoard) -> [I2CInterface]? {
        switch board {
        case .CHIP:
            return [I2CCHIP[1]!, I2CCHIP[2]!]
        case .RaspberryPiRev1,
             .RaspberryPiRev2,
             .RaspberryPiPlusZero,
             .RaspberryPiZero2,
             .RaspberryPi2,
             .RaspberryPi3,
             .RaspberryPi4:
            return [I2CRPI[0]!, I2CRPI[1]!]
        default:
            return nil
        }
    }
}

// MARK: - I2C Presets
extension SwiftyGPIO {
    // RaspberryPis I2Cs
    static let I2CRPI: [Int:I2CInterface] = [
        0: SysFSI2C(i2cId: 0),
        1: SysFSI2C(i2cId: 1)
    ]

    // CHIP I2Cs
    // i2c.0: connected to the AXP209 chip
    // i2c.1: after 4.4.13-ntc-mlc connected to the U13 header I2C interface
    // i2c.2: connected to the U14 header I2C interface, XIO gpios are connected on this bus
    static let I2CCHIP: [Int:I2CInterface] = [
        1: SysFSI2C(i2cId: 1),
        2: SysFSI2C(i2cId: 2),
    ]
}

// MARK: I2C

public protocol I2CInterface {
    func isReachable(_ address: Int) -> Bool
    func setPEC(_ address: Int, enabled: Bool)
    func readByte(_ address: Int) -> UInt8
    func readByte(_ address: Int, command: UInt8) -> UInt8
    func readWord(_ address: Int, command: UInt8) -> UInt16
    func readData(_ address: Int, command: UInt8) -> [UInt8]
    func readI2CData(_ address: Int, command: UInt8) -> [UInt8]
    func writeQuick(_ address: Int)
    func writeByte(_ address: Int, value: UInt8)
    func writeByte(_ address: Int, command: UInt8, value: UInt8)
    func writeWord(_ address: Int, command: UInt8, value: UInt16)
    func writeData(_ address: Int, command: UInt8, values: [UInt8])
    func writeI2CData(_ address: Int, command: UInt8, values: [UInt8])
    // One-shot rd/wr not provided

    func isReachableOrThrow(_ address: Int) throws -> Bool
    func setPECOrThrow(_ address: Int, enabled: Bool) throws
    func readByteOrThrow(_ address: Int) throws -> UInt8
    func readByteOrThrow(_ address: Int, command: UInt8) throws -> UInt8
    func readWordOrThrow(_ address: Int, command: UInt8) throws -> UInt16
    func readDataOrThrow(_ address: Int, command: UInt8) throws -> [UInt8]
    func readI2CDataOrThrow(_ address: Int, command: UInt8) throws -> [UInt8]
    func writeQuickOrThrow(_ address: Int) throws
    func writeByteOrThrow(_ address: Int, value: UInt8) throws
    func writeByteOrThrow(_ address: Int, command: UInt8, value: UInt8) throws
    func writeWordOrThrow(_ address: Int, command: UInt8, value: UInt16) throws
    func writeDataOrThrow(_ address: Int, command: UInt8, values: [UInt8]) throws
    func writeI2CDataOrThrow(_ address: Int, command: UInt8, values: [UInt8]) throws
}

/// Hardware I2C(SMBus) via SysFS using I2C_SMBUS ioctl
public final class SysFSI2C: I2CInterface {

    let i2cId: Int
    var fd: Int32 = -1
    var currentSlave: Int = -1

    public init(i2cId: Int) {
        self.i2cId=i2cId
    }

    deinit {
        if fd != -1 {
            closeI2C()
        }
    }

    public func isReachable(_ address: Int) -> Bool {
        do {
            return try isReachableOrThrow(address)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func setPEC(_ address: Int, enabled: Bool) {
        do {
            try setPECOrThrow(address, enabled: enabled)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func readByte(_ address: Int) -> UInt8 {
        do {
            return try readByteOrThrow(address)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func readByte(_ address: Int, command: UInt8) -> UInt8 {
        do {
            return try readByteOrThrow(address, command: command)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func readWord(_ address: Int, command: UInt8) -> UInt16 {
        do {
            return try readWordOrThrow(address, command: command)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func readData(_ address: Int, command: UInt8) -> [UInt8] {
        do {
            return try readDataOrThrow(address, command: command)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func readI2CData(_ address: Int, command: UInt8) -> [UInt8] {
        do {
            return try readI2CDataOrThrow(address, command: command)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func writeQuick(_ address: Int) {
        do {
            try writeQuickOrThrow(address)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func writeByte(_ address: Int, value: UInt8) {
        do {
            try writeByteOrThrow(address, value: value)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func writeByte(_ address: Int, command: UInt8, value: UInt8) {
        do {
            try writeByteOrThrow(address, command: command, value: value)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func writeWord(_ address: Int, command: UInt8, value: UInt16) {
        do {
            try writeWordOrThrow(address, command: command, value: value)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func writeData(_ address: Int, command: UInt8, values: [UInt8]) {
        do {
            try writeDataOrThrow(address, command: command, values: values)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func writeI2CData(_ address: Int, command: UInt8, values: [UInt8]) {
        do {
            try writeI2CDataOrThrow(address, command: command, values: values)
        } catch {
            SwiftyGPIO.abort(logging: error)
        }
    }

    public func readByteOrThrow(_ address: Int) throws -> UInt8 {
        try setSlaveAddress(address)

        let r =  try i2c_smbus_read_byte()

        if r < 0 {
            throw SwiftyGPIO.IoError(.read, detail: "I2C read failed")
        }
      #if swift(>=4.0)
        return UInt8(truncatingIfNeeded: r)
      #else
        return UInt8(truncatingBitPattern: r)
      #endif
    }

    public func readByteOrThrow(_ address: Int, command: UInt8) throws -> UInt8 {
        try setSlaveAddress(address)

        let r = try i2c_smbus_read_byte_data(command: command)

        if r < 0 {
            throw SwiftyGPIO.IoError(.read, detail: "I2C read failed")
        }
      #if swift(>=4.0)
        return UInt8(truncatingIfNeeded: r)
      #else
        return UInt8(truncatingBitPattern: r)
      #endif
    }

    public func readWordOrThrow(_ address: Int, command: UInt8) throws -> UInt16 {
        try setSlaveAddress(address)

        let r = try i2c_smbus_read_word_data(command: command)

        if r < 0 {
            throw SwiftyGPIO.IoError(.read, detail: "I2C read failed")
        }
      #if swift(>=4.0)
        return UInt16(truncatingIfNeeded: r)
      #else
        return UInt16(truncatingBitPattern: r)
      #endif
    }

    public func readDataOrThrow(_ address: Int, command: UInt8) throws -> [UInt8] {
        var buf: [UInt8] = [UInt8](repeating:0, count: 32)

        try setSlaveAddress(address)

        let r = try i2c_smbus_read_block_data(command: command, values: &buf)

        if r < 0 {
            throw SwiftyGPIO.IoError(.read, detail: "I2C read failed")
        }
        return buf
    }

    public func readI2CDataOrThrow(_ address: Int, command: UInt8) throws -> [UInt8] {
        var buf: [UInt8] = [UInt8](repeating:0, count: 32)

        try setSlaveAddress(address)

        let r = try i2c_smbus_read_i2c_block_data(command: command, values: &buf)

        if r < 0 {
            throw SwiftyGPIO.IoError(.read, detail: "I2C read failed")
        }
        return buf
    }
 
    public func writeQuickOrThrow(_ address: Int) throws {
        try setSlaveAddress(address)

        let r = try i2c_smbus_write_quick(value: I2C_SMBUS_WRITE)

        if r < 0 {
            throw SwiftyGPIO.IoError(.write, detail: "I2C write failed")
        }
    }

    public func writeByteOrThrow(_ address: Int, value: UInt8) throws {
        try setSlaveAddress(address)

        let r = try i2c_smbus_write_byte(value: value)

        if r < 0 {
            throw SwiftyGPIO.IoError(.write, detail: "I2C write failed")
        }
    }

    public func writeByteOrThrow(_ address: Int, command: UInt8, value: UInt8) throws {
        try setSlaveAddress(address)

        let r = try i2c_smbus_write_byte_data(command: command, value: value)

        if r < 0 {
            throw SwiftyGPIO.IoError(.write, detail: "I2C write failed")
        }
    }

    public func writeWordOrThrow(_ address: Int, command: UInt8, value: UInt16) throws {
        try setSlaveAddress(address)

        let r = try i2c_smbus_write_word_data(command: command, value: value)

        if r < 0 {
            throw SwiftyGPIO.IoError(.write, detail: "I2C write failed")
        }
    }

    public func writeDataOrThrow(_ address: Int, command: UInt8, values: [UInt8]) throws {
        try setSlaveAddress(address)

        let r = try i2c_smbus_write_block_data(command: command, values: values)

        if r < 0 {
            throw SwiftyGPIO.IoError(.write, detail: "I2C write failed")
        }
    }

    public func writeI2CDataOrThrow(_ address: Int, command: UInt8, values: [UInt8]) throws {
        try setSlaveAddress(address)

        let r = try i2c_smbus_write_i2c_block_data(command: command, values: values)

        if r < 0 {
            throw SwiftyGPIO.IoError(.write, detail: "I2C write failed")
        }
    }
 
    public func isReachableOrThrow(_ address: Int) throws -> Bool {
        try setSlaveAddress(address)

        var r: Int32 =  -1
        
        // Mimic the behaviour of i2cdetect, performing bogus read/quickwrite depending on the address
        switch(address){
            case 0x3...0x2f:
                r = try i2c_smbus_write_quick(value: 0)
            case 0x30...0x37:
                r = try i2c_smbus_read_byte()
            case 0x38...0x4f:
                r = try i2c_smbus_write_quick(value: 0)
            case 0x50...0x5f:
                r = try i2c_smbus_read_byte()
            case 0x60...0x77:
                r = try i2c_smbus_write_quick(value: 0)
            default:
                r = try i2c_smbus_read_byte()
        }

        guard r >= 0 else { return false }

        return true
    }

    public func setPECOrThrow(_ address: Int, enabled: Bool) throws {
        try setSlaveAddress(address)

        let r =  ioctl(fd, I2C_PEC, enabled ? 1 : 0)

        if r != 0 {
            throw SwiftyGPIO.IoError(.ioControl, detail: "I2C communication failed")
        }
    }

    private func setSlaveAddress(_ to: Int) throws {

        if fd == -1 {
            try openI2C()
        }

        guard currentSlave != to else {return}

        let r = ioctl(fd, I2C_SLAVE_FORCE, CInt(to))
        if r != 0 {
            throw SwiftyGPIO.IoError(.ioControl, detail: "I2C communication failed")
        }

        currentSlave = to
    }

    private func openI2C() throws {
        let fd = open(I2CBASEPATH+String(i2cId), O_RDWR)
        guard fd > 0 else {
            throw SwiftyGPIO.IoError(.open, detail: "Couldn't open the I2C device")
        }

        self.fd = fd
    }

    private func closeI2C() {
        close(fd)
    }

    // Private functions
    // Swift implementation of the smbus functions provided by i2c-dev

    private struct i2c_smbus_ioctl_data {
        var read_write: UInt8
        var command: UInt8
        var size: Int32
        var data: UnsafeMutablePointer<UInt8>? //union: UInt8, UInt16, [UInt8]33
    }

    private func smbus_ioctl(rw: UInt8, command: UInt8, size: Int32, data: UnsafeMutablePointer<UInt8>?) throws -> Int32 {
        if fd == -1 {
            try openI2C()
        }

        var args = i2c_smbus_ioctl_data(read_write: rw,
                                        command: command,
                                        size: size,
                                        data: data)
        return ioctl(fd, I2C_SMBUS, &args)
    }

    //
    // Read
    //

    private func i2c_smbus_read_byte() throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_DEFAULT_PAYLOAD_LENGTH)

        let r = try smbus_ioctl(rw: I2C_SMBUS_READ,
                            command: 0,
                            size: I2C_SMBUS_BYTE,
                            data: &data)
        if r >= 0 {
            return Int32(data[0])
        } else {
            return -1
        }
    }

    private func i2c_smbus_read_byte_data(command: UInt8) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_DEFAULT_PAYLOAD_LENGTH)

        let r = try smbus_ioctl(rw: I2C_SMBUS_READ,
                            command: command,
                            size: I2C_SMBUS_BYTE_DATA,
                            data: &data)
        if r >= 0 {
            return Int32(data[0])
        } else {
            return -1
        }
    }

    private func i2c_smbus_read_word_data(command: UInt8) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_DEFAULT_PAYLOAD_LENGTH)

        let r = try smbus_ioctl(rw: I2C_SMBUS_READ,
                            command: command,
                            size: I2C_SMBUS_WORD_DATA,
                            data: &data)
        if r >= 0 {
            return (Int32(data[1]) << 8) + Int32(data[0])
        } else {
            return -1
        }
    }

    private func i2c_smbus_read_block_data(command: UInt8, values: inout [UInt8]) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_DEFAULT_PAYLOAD_LENGTH)

        let r = try smbus_ioctl(rw: I2C_SMBUS_READ,
                            command: command,
                            size: I2C_SMBUS_BLOCK_DATA,
                            data: &data)
        if r >= 0 {
            for i in 0..<Int(data[0]) {
                values[i] = data[i+1]
            }
            return Int32(data[0])
        } else {
            return -1
        }
    }

    private func i2c_smbus_read_i2c_block_data(command: UInt8, values: inout [UInt8]) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_DEFAULT_PAYLOAD_LENGTH)

        let r = try smbus_ioctl(rw: I2C_SMBUS_READ,
                            command: command,
                            size: I2C_SMBUS_I2C_BLOCK_DATA,
                            data: &data)
        if r >= 0 {
            for i in 0..<Int(data[0]) {
                values[i] = data[i+1]
            }
            return Int32(data[0])
        } else {
            return -1
        }
    }

 
    //
    // Write
    //

    private func i2c_smbus_write_quick(value: UInt8) throws -> Int32 {
        return try smbus_ioctl(rw: value,
                           command: 0,
                           size: I2C_SMBUS_QUICK,
                           data: nil)
    }

    private func i2c_smbus_write_byte(value: UInt8) throws -> Int32 {
        return try smbus_ioctl(rw: I2C_SMBUS_WRITE,
                           command: value,
                           size: I2C_SMBUS_BYTE,
                           data: nil)
    }

    private func i2c_smbus_write_byte_data(command: UInt8, value: UInt8) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_DEFAULT_PAYLOAD_LENGTH)

        data[0] = value

        return try smbus_ioctl(rw: I2C_SMBUS_WRITE,
                           command: command,
                           size: I2C_SMBUS_BYTE_DATA,
                           data: &data)
    }

    private func i2c_smbus_write_word_data(command: UInt8, value: UInt16) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_DEFAULT_PAYLOAD_LENGTH)

        data[0] = UInt8(value & 0xFF)
        data[1] = UInt8(value >> 8)

        return try smbus_ioctl(rw: I2C_SMBUS_WRITE,
                           command: command,
                           size: I2C_SMBUS_WORD_DATA,
                           data: &data)
    }

    private func i2c_smbus_write_block_data(command: UInt8, values: [UInt8]) throws -> Int32 {

        guard values.count<=I2C_DEFAULT_PAYLOAD_LENGTH else { throw SwiftyGPIO.IoError(.write, detail: "Invalid data length, can't send more than \(I2C_DEFAULT_PAYLOAD_LENGTH) bytes!") }

        var data = [UInt8](repeating:0, count: values.count+1)

        for i in 1...values.count {
            data[i] = values[i-1]
        }
        data[0] = UInt8(values.count)

        return try smbus_ioctl(rw: I2C_SMBUS_WRITE,
                           command: command,
                           size: I2C_SMBUS_BLOCK_DATA,
                           data: &data)
    }

    private func i2c_smbus_write_i2c_block_data(command: UInt8, values: [UInt8]) throws -> Int32 {

        guard values.count<=I2C_DEFAULT_PAYLOAD_LENGTH else { throw SwiftyGPIO.IoError(.write, detail: "Invalid data length, can't send more than \(I2C_DEFAULT_PAYLOAD_LENGTH) bytes!") }

        var data = [UInt8](repeating:0, count: values.count+1)

        for i in 1...values.count {
            data[i] = values[i-1]
        }
        data[0] = UInt8(values.count)

        return try smbus_ioctl(rw: I2C_SMBUS_WRITE,
                           command: command,
                           size: I2C_SMBUS_I2C_BLOCK_DATA,
                           data: &data)
    }
 
}

// MARK: - I2C/SMBUS Constants
internal let I2C_SMBUS_READ: UInt8 =   1
internal let I2C_SMBUS_WRITE: UInt8 =  0

internal let I2C_SMBUS_QUICK: Int32 = 0
internal let I2C_SMBUS_BYTE: Int32 = 1
internal let I2C_SMBUS_BYTE_DATA: Int32 = 2
internal let I2C_SMBUS_WORD_DATA: Int32 = 3
internal let I2C_SMBUS_BLOCK_DATA: Int32 = 5
//Not implemented: I2C_SMBUS_I2C_BLOCK_BROKEN  6
//Not implemented:  I2C_SMBUS_BLOCK_PROC_CALL   7
internal let I2C_SMBUS_I2C_BLOCK_DATA: Int32 = 8

internal let I2C_SLAVE: UInt = 0x703
internal let I2C_SLAVE_FORCE: UInt = 0x706
internal let I2C_RDWR: UInt = 0x707
internal let I2C_PEC: UInt = 0x708
internal let I2C_SMBUS: UInt = 0x720
internal let I2C_DEFAULT_PAYLOAD_LENGTH: Int = 32
internal let I2CBASEPATH="/dev/i2c-"

// MARK: - Darwin / Xcode Support
#if !os(Linux)
    private var O_SYNC: CInt { fatalError("Linux only") }
#endif
