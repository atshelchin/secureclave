// Parse the attestation object from iOS
const attestationHex = "a363666d74646e6f6e656761747453746d74a06861757468446174615898b2c0ba7bb038330daf4347f16babea5dfb15ed8f9f451fc96328e1760b3786885d00000000fbfc3007154e4ecc8c0b6e020557d7bd0014e0a9e663cc8cc7e11a246e301f7714f139799fb9a501020326200121582037c776da2f297c6a934ee8fb75a14a8dd55288b6efa09ea9e458634c53e134a7225820f6f8e1c91032ae2d7b699130a180d487a505c16174b184696c28a8eaf32567a9"

// Convert hex to bytes
const attestationBytes = Buffer.from(attestationHex, 'hex')

console.log("Attestation Object Analysis")
console.log("=" .repeat(50))
console.log("Total size:", attestationBytes.length, "bytes")
console.log("")

// CBOR structure
console.log("CBOR Structure:")
console.log("  0xa3 = map with 3 items")
console.log("")

// Skip CBOR headers to find authData
// Looking for the authData value (after "authData" key)
let authDataStart = -1
const authDataKey = Buffer.from("6861757468446174615898", 'hex') // "authData" in CBOR + length prefix

for (let i = 0; i < attestationBytes.length - authDataKey.length; i++) {
    let match = true
    for (let j = 0; j < authDataKey.length; j++) {
        if (attestationBytes[i + j] !== authDataKey[j]) {
            match = false
            break
        }
    }
    if (match) {
        authDataStart = i + authDataKey.length
        console.log("Found authData at offset:", authDataStart)
        break
    }
}

if (authDataStart >= 0) {
    const authData = attestationBytes.slice(authDataStart)
    console.log("\nAuthData (", authData.length, "bytes):")
    
    // Parse authData structure
    const rpIdHash = authData.slice(0, 32)
    const flags = authData[32]
    const counter = authData.slice(33, 37)
    
    console.log("  RP ID Hash:", rpIdHash.toString('hex'))
    console.log("  Flags:", '0x' + flags.toString(16))
    console.log("    - UP:", (flags & 0x01) !== 0)
    console.log("    - UV:", (flags & 0x04) !== 0)
    console.log("    - AT:", (flags & 0x40) !== 0)
    console.log("    - ED:", (flags & 0x80) !== 0)
    console.log("  Counter:", counter.toString('hex'))
    
    // If AT flag is set, parse attested credential data
    if ((flags & 0x40) !== 0) {
        console.log("\n✅ AT flag is set - Credential data present!")
        
        let offset = 37
        
        // AAGUID (16 bytes)
        const aaguid = authData.slice(offset, offset + 16)
        console.log("  AAGUID:", aaguid.toString('hex'))
        offset += 16
        
        // Credential ID length (2 bytes, big-endian)
        const credIdLen = (authData[offset] << 8) | authData[offset + 1]
        console.log("  Credential ID Length:", credIdLen)
        offset += 2
        
        // Credential ID
        const credId = authData.slice(offset, offset + credIdLen)
        console.log("  Credential ID:", credId.toString('hex'))
        offset += credIdLen
        
        // Public Key (COSE format)
        console.log("\n🔑 PUBLIC KEY STARTS AT BYTE", offset)
        const publicKeyData = authData.slice(offset)
        console.log("  Public key data (" + publicKeyData.length + " bytes):")
        console.log("  ", publicKeyData.toString('hex'))
        
        // Parse COSE key
        console.log("\n📊 Parsing COSE Key:")
        
        // Look for x and y coordinates
        // x coordinate marker: 0x21 0x58 0x20 (label -2, byte string of 32)
        // y coordinate marker: 0x22 0x58 0x20 (label -3, byte string of 32)
        
        let x = null, y = null
        
        for (let i = 0; i < publicKeyData.length - 34; i++) {
            if (publicKeyData[i] === 0x21 && publicKeyData[i+1] === 0x58 && publicKeyData[i+2] === 0x20) {
                x = publicKeyData.slice(i+3, i+35)
                console.log("  Found X at offset", i, ":", x.toString('hex'))
            }
            if (publicKeyData[i] === 0x22 && publicKeyData[i+1] === 0x58 && publicKeyData[i+2] === 0x20) {
                y = publicKeyData.slice(i+3, i+35)
                console.log("  Found Y at offset", i, ":", y.toString('hex'))
            }
        }
        
        if (x && y) {
            console.log("\n✅✅✅ PUBLIC KEY EXTRACTED!")
            const publicKey = Buffer.concat([Buffer.from([0x04]), x, y])
            console.log("Uncompressed public key (65 bytes):")
            console.log("0x" + publicKey.toString('hex'))
        }
    } else {
        console.log("\n❌ AT flag not set - No credential data")
    }
}