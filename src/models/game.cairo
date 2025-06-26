use dojo::event::EventStorage;
use dojo::model::ModelStorage;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait, WorldStorage, WorldStorageTrait};

use starknet::{ContractAddress, get_caller_address};

use openzeppelin_token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
use tournaments::components::interfaces::{IGameTokenDispatcher, IGameTokenDispatcherTrait};

#[derive(IntrospectPacked, Copy, Drop, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub game_id: u64,
    pub score: u32,
}

#[generate_trait]
pub impl GameOwnerImpl of GameOwnerTrait {
    fn update_metadata(self: Game, world: WorldStorage) {
        let (contract_address, _) = world.dns(@"game_token").unwrap();
        let game_token_dispatcher = IGameTokenDispatcher { contract_address };
        game_token_dispatcher.emit_metadata_update(self.game_id.into());
    }

    fn assert_owner(self: Game, world: WorldStorage) {
        let (contract_address, _) = world.dns(@"game_token").unwrap();
        let game_token = IERC721Dispatcher { contract_address };
        assert(game_token.owner_of(self.game_id.into()) == get_caller_address(), 'Not Owner');
    }

    fn exists(self: Game) -> bool {
        self.score > 0
    }
}

#[derive(Copy, Drop, Serde)]
#[dojo::event(historical: true)]
pub struct GameActionEvent {
    #[key]
    tx_hash: felt252,
    game_id: u64,
    count: u16,
}


#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Moves {
    #[key]
    pub player: ContractAddress,
    pub remaining: u8,
    pub last_direction: Option<Direction>,
    pub can_move: bool,
}

#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct DirectionsAvailable {
    #[key]
    pub player: ContractAddress,
    pub directions: Array<Direction>,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Position {
    #[key]
    pub player: ContractAddress,
    pub vec: Vec2,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct PositionCount {
    #[key]
    pub identity: ContractAddress,
    pub position: Span<(u8, u128)>,
}


#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum Direction {
    Left,
    Right,
    Up,
    Down,
}


#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
pub struct Vec2 {
    pub x: u32,
    pub y: u32,
}


impl DirectionIntoFelt252 of Into<Direction, felt252> {
    fn into(self: Direction) -> felt252 {
        match self {
            Direction::Left => 1,
            Direction::Right => 2,
            Direction::Up => 3,
            Direction::Down => 4,
        }
    }
}

impl OptionDirectionIntoFelt252 of Into<Option<Direction>, felt252> {
    fn into(self: Option<Direction>) -> felt252 {
        match self {
            Option::None => 0,
            Option::Some(d) => d.into(),
        }
    }
}

#[generate_trait]
impl Vec2Impl of Vec2Trait {
    fn is_zero(self: Vec2) -> bool {
        if self.x - self.y == 0 {
            return true;
        }
        false
    }

    fn is_equal(self: Vec2, b: Vec2) -> bool {
        self.x == b.x && self.y == b.y
    }
}

#[cfg(test)]
mod tests {
    use super::{Vec2, Vec2Trait};

    #[test]
    fn test_vec_is_zero() {
        assert(Vec2Trait::is_zero(Vec2 { x: 0, y: 0 }), 'not zero');
    }

    #[test]
    fn test_vec_is_equal() {
        let position = Vec2 { x: 420, y: 0 };
        assert(position.is_equal(Vec2 { x: 420, y: 0 }), 'not equal');
    }
}
