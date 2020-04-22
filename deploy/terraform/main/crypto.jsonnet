{
  resource+: {
    google_kms_key_ring+: {
      key_ring: $.proj_mixin + {
        name: 'key_ring',
        location: $.config.region,
      }
    },
    
    google_kms_crypto_key+: {
      crypto_key: {
        name: 'crypto_key',
        key_ring: '${google_kms_key_ring.key_ring.self_link}'
      },
    }, 
  }
}
