use starknet::{ContractAddress, contract_address_const};

pub fn DEFAULT_NAMESPACE() -> ByteArray {
    "dojo_starter"
}

pub fn TOKEN_NAME() -> ByteArray {
    ("Game")
}
pub fn TOKEN_SYMBOL() -> ByteArray {
    ("GAME")
}
pub fn BASE_URI() -> ByteArray {
    ("https://game.io")
}

pub fn GAME_NAME() -> felt252 {
    ('Game Name')
}
pub fn GAME_DESCRIPTION() -> ByteArray {
    ("Game Description")
}
pub fn GAME_DEVELOPER() -> felt252 {
    ('Game Developer')
}
pub fn GAME_PUBLISHER() -> felt252 {
    ('Game Publisher')
}
pub fn GAME_GENRE() -> felt252 {
    ('Game Genre')
}
pub fn GAME_IMAGE() -> ByteArray {
    ("https://game.io/image.png")
}
pub fn GAME_CREATOR() -> ContractAddress {
    contract_address_const::<'GAME CREATOR'>()
}