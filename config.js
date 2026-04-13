/**
 * 陳艾倫大事紀 - 設定檔（加密版）
 * 僅允許以下網域存取：
 *   - localhost / 127.0.0.1（本機開發）
 *   - allenchen1113official.github.io（GitHub Pages）
 *   - file:// 直接開啟
 *
 * 使用 AES-256-GCM + PBKDF2 加密，金鑰由網域名稱衍生。
 * 複製到其他網域將無法解密。
 */

// ── 各網域對應的加密資料（AES-256-GCM） ──────────────────────────
const _ENCRYPTED = {
  "localhost": {
    "data": "H7FCc2uDHaoze3mj9MmX7Phur5yszW6kxA6VXMZ0FvX7aYxY8PLZ1EDeiYU7r+OgMCeg+ibOBrwpKhG1k3peVPUo3Zg4mvL/HNbh2yXJADKusIjvV2Nc4RXCAYYlIAsaDJMJ4R4sqRp9BTTbhU+ZgBSBagna47AHjtSSWaiCTrTIRIfJY7epdl80BG+fjXpz9ehHlEiUfeYCVcmGFOLfCVAm1STTLKITyG4DFTuDv8vmOaJe/uccYjEJQxFn59Bjw319T4npI6BnYI/LCL8rOJqgJ4ajRDIzLqu+IIYHQOXyxfGchVCNXiFM8cancb3HlcURW8ETrKvvA6hA1AqBK8tcPfdjC4CR/CCcEetiKlGD+OHmff7ZZF4q3GZ8oPULhSE=",
    "iv": "jBa45rwG1M5cohdH",
    "salt": "9lfWhA7xMPliokAs1/XAng=="
  },
  "127.0.0.1": {
    "data": "YjRRL29z38gvZPfnMEDgWTIJ9nYL3I1cNZcdKYTfFZQLtrglnsKk9DA2vvsD6nPkASp8gxITIDRfYiJOazdXfJvp/L8V3fpT6kpBl1TqTcmNuQvZKaH032afisM/FkAB/F5ZVqd4/2e248lcLqaeCgLRzCQoVKSA+fJraow0U2/rGoBEoKcYz/okjvokfryrkY+qKuBODc0fSXcE6O2Wbix8uwgM68iEeBuKPIwlJw+MKplcYgvK0ZEhBbbREdyJEfTqJtIjp3aVwqjMkUF4utIi+wYmDnJJyIBKqthDxKov0JaJMQ3zO9FjKWWIAuxnIxcrMQR6tq6zVHpQt4WKtC/fkdYFjh7I4sIoAuJ5zVWpWcB6RFgH/ZteY7vUh/I1xFs=",
    "iv": "gsZyQzRhO5iWAW1U",
    "salt": "985QBGARQdqqvsmaZ0GuZg=="
  },
  "allenchen1113official.github.io": {
    "data": "lLv3lFx0St4MVrJtV0pp+G3nw5YhNCAKmdNeIeZ8FqeHAYh+L5R30BsdWmZU6D0ZkHJOTcQ9PDAMeQk8XGu/eZ1fbxcK21hmZHhLTYrH+e6gehvW9vMhPCohC9MzFA+uuyfTnuWWaXuqbWTTqgvN9BAiXnD+eozMgwqaYhpiMCgaCiZ7DADoBVVLR37zvS9kMTlfZEsOa0m69O/HkBWBl3Jdhlss4h4dVry2R9bWgDbb9A7p0hZe77Lr4tF38yYKgjlAVcuH5Hn3zYNdHLTYabHi6p0owoPrCA2FHsOaRBBCwyKG9rGTAitVORQvZ09T+MkJ+j/qvxmDN8NSJgMCD3GwmrnBNi/paD0pqRKGU+nir7Re/Cs1QicXV1v18NbxZhM=",
    "iv": "NuXsr/ZJdgLN/RjW",
    "salt": "Jma4GBG74H2qGpDs5GZ9Fg=="
  },
  "": {
    "data": "gaxNuS7UtO8U2usnVfIe5pl8aynfvdTMENYm9Ee8Hs2sSd0B438YzJs5eM5bfN/iKUUK0FAjJ21beAeSFiDvF1U/ek+iHMZQVszx7rxJp6XQ+ws0QdvPDdWb3A+Tkz14oQl3ZZ9Le5DRUUwH2WRh+lyPHGJf7Lh5lblUkj8RzWhIthdn7NKbXLUJr7JWPIOki/ll4HMZZiaUnmTVLkOyVLkTqnUoXTjjxKbRc4nZ1OdTfMZOXXU5HO72GEfttXdkT8oe5+H1H7A0/7jbtqzGwWja6ApI44Vv7HJiQ2xljVb51Y9y3zrmbj5190IWUhs4mOVEWvKEyk0ouVFVftsHheIGnZSeskA21oLOQ2qBI4Jp0IQHcQEJNy7y+LOaEWUJuzM=",
    "iv": "eENc3NpgoWTt0S7s",
    "salt": "//5yzM/WZo4UkMbz4Aiu5Q=="
  }
};

// ── 解密函式（Web Crypto API，AES-256-GCM + PBKDF2） ──────────────
const _k = [97,108,108,101,110,45,97,110,110,117,108,105,45,49,57,55,53];

function _b64(b64) {
  return Uint8Array.from(atob(b64), c => c.charCodeAt(0));
}

async function getSupabaseConfig() {
  const domain = window.location.hostname;
  const enc = _ENCRYPTED[domain];
  if (!enc) {
    throw new Error(`[Config] 網域 "${domain || 'file://'}" 未授權，無法存取設定。`);
  }
  const pepper = String.fromCharCode(..._k);
  const password = domain + pepper;
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveKey']
  );
  const key = await crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt: _b64(enc.salt), iterations: 100000, hash: 'SHA-256' },
    keyMaterial,
    { name: 'AES-GCM', length: 256 },
    false,
    ['decrypt']
  );
  const decrypted = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: _b64(enc.iv) },
    key,
    _b64(enc.data)
  );
  return JSON.parse(new TextDecoder().decode(decrypted));
}
