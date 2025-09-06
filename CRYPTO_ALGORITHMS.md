# 🔐 加密算法详解

## Secure Enclave 使用的算法

### EC256 / P-256 详细说明

**是的，EC256 就是 P-256！** 它们是同一个椭圆曲线的不同叫法。

#### 名称对照表

| 名称 | 全称 | 说明 |
|------|------|------|
| **EC256** | Elliptic Curve 256-bit | 通用名称，表示256位椭圆曲线 |
| **P-256** | NIST P-256 | NIST（美国国家标准与技术研究院）标准名称 |
| **secp256r1** | Standards for Efficient Cryptography | 技术规范名称 |
| **prime256v1** | Prime 256-bit version 1 | OpenSSL 中的名称 |

#### 在 iOS/Apple 生态系统中

```swift
// Apple 使用的常量
kSecAttrKeyTypeECSECPrimeRandom  // 这就是 P-256
kSecAttrKeySizeInBits: 256       // 256位密钥长度
```

### 技术规格

#### 椭圆曲线参数
- **曲线方程**: y² = x³ + ax + b (mod p)
- **密钥长度**: 256 bits
- **安全级别**: 128 bits（等同于 3072-bit RSA）
- **签名算法**: ECDSA (Elliptic Curve Digital Signature Algorithm)

#### 公钥格式
```
// 未压缩格式（65字节）
04 || X (32字节) || Y (32字节)

// 压缩格式（33字节）
02/03 || X (32字节)
```

### Secure Enclave 特性

#### 硬件保护
- 私钥**永远不会**离开 Secure Enclave
- 私钥在硬件中生成
- 私钥无法导出或复制
- 即使越狱也无法提取

#### 支持的操作
1. **密钥生成** - 在硬件中生成 P-256 密钥对
2. **签名** - 使用 ECDSA-SHA256
3. **验证** - 可以在 Secure Enclave 外部验证
4. **加密/解密** - ECIES (较少使用)

### 代码示例

#### 生成 P-256 密钥
```swift
// Secure Enclave 中生成 P-256 密钥
let attributes: [String: Any] = [
    kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,  // P-256
    kSecAttrKeySizeInBits: 256,
    kSecAttrTokenID: kSecAttrTokenIDSecureEnclave
]
```

#### 签名算法
```swift
// 使用 ECDSA with SHA-256
SecKeyCreateSignature(
    privateKey,
    .ecdsaSignatureMessageX962SHA256,  // ECDSA + SHA256
    data,
    &error
)
```

### 为什么选择 P-256？

#### 优点
✅ **标准化** - NIST 标准，广泛支持
✅ **性能** - 在移动设备上性能优异
✅ **安全性** - 128位安全级别足够大多数用途
✅ **兼容性** - 被 TLS、WebAuthn、Passkeys 等广泛支持
✅ **硬件加速** - Secure Enclave 原生支持

#### 与其他算法对比

| 算法 | 密钥大小 | 安全级别 | Secure Enclave 支持 |
|------|---------|---------|---------------------|
| P-256 (EC256) | 256 bits | 128 bits | ✅ 原生支持 |
| P-384 | 384 bits | 192 bits | ❌ 不支持 |
| P-521 | 521 bits | 256 bits | ❌ 不支持 |
| Ed25519 | 256 bits | 128 bits | ❌ 不支持 |
| RSA-2048 | 2048 bits | 112 bits | ❌ 不支持 |
| RSA-3072 | 3072 bits | 128 bits | ❌ 不支持 |

### 实际应用

#### 1. Passkeys / WebAuthn
```javascript
// Web 端 Passkeys 也使用 P-256
{
  publicKey: {
    pubKeyCredParams: [{
      type: "public-key",
      alg: -7  // ES256 = P-256 with SHA-256
    }]
  }
}
```

#### 2. Apple Pay
- 使用 P-256 进行交易签名

#### 3. iMessage 加密
- 使用 P-256 进行密钥交换

#### 4. TLS/SSL
- ECDHE-ECDSA-P256 密码套件

### 安全性分析

#### 当前状态（2025年）
- ✅ P-256 仍然被认为是安全的
- ✅ 没有已知的实际攻击方法
- ✅ 量子计算威胁尚未实现

#### 未来考虑
- ⚠️ 量子计算可能在未来10-20年构成威胁
- 📅 NIST 正在标准化后量子密码算法
- 🔄 Apple 可能在未来更新 Secure Enclave 支持新算法

### 验证公钥格式

当你导出公钥时，可以看到：

```swift
// 原始公钥数据（65字节）
04 // 未压缩标识
XX...XX // X坐标（32字节）
YY...YY // Y坐标（32字节）

// Base64 编码后约 88 个字符
// Hex 编码后 130 个字符
```

### 互操作性

P-256 公钥可以在以下环境使用：
- ✅ OpenSSL
- ✅ Web Crypto API
- ✅ Java (Bouncy Castle)
- ✅ Python (cryptography)
- ✅ Go (crypto/elliptic)
- ✅ Rust (p256 crate)

### 总结

**EC256 = P-256 = secp256r1** 

它们都是指同一条 NIST P-256 椭圆曲线，这是：
- Apple Secure Enclave 唯一支持的椭圆曲线
- 业界标准的选择
- 性能和安全性的良好平衡
- Passkeys 和 WebAuthn 的默认算法