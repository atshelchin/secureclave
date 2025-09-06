// 解析 authenticatorData
const authenticatorDataHex = "b2c0ba7bb038330daf4347f16babea5dfb15ed8f9f451fc96328e1760b3786881d00000000"

console.log("🔍 解析 AuthenticatorData")
console.log("=" .repeat(60))

const authData = Buffer.from(authenticatorDataHex, 'hex')
console.log("总长度:", authData.length, "字节")
console.log("完整数据:", '0x' + authenticatorDataHex)
console.log("")

// 1. RP ID Hash (32 字节)
const rpIdHash = authData.slice(0, 32)
console.log("1️⃣ RP ID Hash (字节 0-31):")
console.log("   值:", rpIdHash.toString('hex'))
console.log("   说明: 这是 RP ID 的 SHA-256 哈希")
console.log("   对应: SHA256('atshelchin.github.io')")
console.log("")

// 2. Flags (1 字节)
const flags = authData[32]
console.log("2️⃣ Flags (字节 32):")
console.log("   十六进制: 0x" + flags.toString(16))
console.log("   二进制: " + flags.toString(2).padStart(8, '0'))
console.log("   十进制:", flags)
console.log("")

// 解析每个 flag
console.log("   Flag 详解:")
console.log("   ┌─────┬─────┬──────────────────────────────┐")
console.log("   │ Bit │ 值  │ 含义                         │")
console.log("   ├─────┼─────┼──────────────────────────────┤")
console.log(`   │  0  │  ${(flags & 0x01) ? '1' : '0'}  │ UP (User Present) - 用户在场 │`)
console.log(`   │  1  │  ${(flags & 0x02) ? '1' : '0'}  │ RFU1 - 保留位                │`)
console.log(`   │  2  │  ${(flags & 0x04) ? '1' : '0'}  │ UV (User Verified) - 用户验证│`)
console.log(`   │  3  │  ${(flags & 0x08) ? '1' : '0'}  │ BE (Backup Eligible) - 可备份│`)
console.log(`   │  4  │  ${(flags & 0x10) ? '1' : '0'}  │ BS (Backup State) - 已备份   │`)
console.log(`   │  5  │  ${(flags & 0x20) ? '1' : '0'}  │ RFU2 - 保留位                │`)
console.log(`   │  6  │  ${(flags & 0x40) ? '1' : '0'}  │ AT (Attested Cred) - 凭证数据│`)
console.log(`   │  7  │  ${(flags & 0x80) ? '1' : '0'}  │ ED (Extension Data) - 扩展   │`)
console.log("   └─────┴─────┴──────────────────────────────┘")
console.log("")

console.log("   激活的标志:")
if (flags & 0x01) console.log("   ✅ UP - 用户在场（点击了确认）")
if (flags & 0x04) console.log("   ✅ UV - 用户已验证（Face ID/Touch ID）")
if (flags & 0x08) console.log("   ✅ BE - 密钥可以备份到 iCloud")
if (flags & 0x10) console.log("   ✅ BS - 密钥已经备份到 iCloud")
if (flags & 0x40) console.log("   ✅ AT - 包含凭证数据（仅创建时）")
if (flags & 0x80) console.log("   ✅ ED - 包含扩展数据")
console.log("")

// 3. Counter (4 字节)
const counter = authData.slice(33, 37)
const counterValue = counter.readUInt32BE(0)
console.log("3️⃣ Counter (字节 33-36):")
console.log("   十六进制:", '0x' + counter.toString('hex'))
console.log("   十进制值:", counterValue)
console.log("   说明: 签名计数器，用于防止重放攻击")
console.log("   注意: iOS Passkeys 通常不递增（隐私保护）")
console.log("")

// 4. 扩展数据检查
console.log("4️⃣ Extensions (可选):")
if (authData.length > 37) {
    console.log("   ⚠️ 检测到额外数据:")
    const extensions = authData.slice(37)
    console.log("   长度:", extensions.length, "字节")
    console.log("   内容:", extensions.toString('hex'))
    
    if (flags & 0x40) {
        console.log("   类型: Attested Credential Data (AT flag = 1)")
        // 解析凭证数据
        if (extensions.length >= 18) {
            const aaguid = extensions.slice(0, 16)
            const credIdLen = extensions.readUInt16BE(16)
            console.log("   - AAGUID:", aaguid.toString('hex'))
            console.log("   - Credential ID Length:", credIdLen)
            if (extensions.length >= 18 + credIdLen) {
                const credId = extensions.slice(18, 18 + credIdLen)
                console.log("   - Credential ID:", credId.toString('hex'))
                if (extensions.length > 18 + credIdLen) {
                    console.log("   - Public Key COSE data follows...")
                }
            }
        }
    } else if (flags & 0x80) {
        console.log("   类型: Extension Data (ED flag = 1)")
    } else {
        console.log("   类型: 未知（flags 未标记）")
    }
} else {
    console.log("   ❌ 无扩展数据（长度 = 37 字节）")
}

console.log("")
console.log("=" .repeat(60))
console.log("📌 总结:")
console.log("这是一个用于签名的 authenticatorData:")
console.log("- 用户在场 (UP) ✅")
console.log("- 用户已验证 (UV) ✅ - 使用了 Face ID/Touch ID")
console.log("- 支持 iCloud 备份 (BE) ✅")
console.log("- 已备份到 iCloud (BS) ✅")
console.log("- 无凭证数据 (AT) ❌ - 这是签名，不是创建")
console.log("- 无扩展数据 (ED) ❌")
console.log("- 计数器为 0 - iOS 的隐私保护特性")