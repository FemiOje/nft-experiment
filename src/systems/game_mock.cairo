#[starknet::interface]
pub trait IGameMock<TContractState> {
    fn start_game(ref self: TContractState, game_id: u64);
    fn end_game(ref self: TContractState, game_id: u64, score: u32);
    fn set_settings(
        ref self: TContractState,
        settings_id: u32,
        name: felt252,
        description: ByteArray,
        exists: bool,
    );
}

#[dojo::contract]
mod game_mock {
    use tournaments::components::interfaces::{ISettings, IGameDetails};
    use tournaments::components::interfaces::{WorldImpl};
    use tournaments::components::libs::game_store::{Store, StoreTrait};
    use tournaments::components::models::game::{SettingsDetails, Score};

    use dojo_starter::constants::{DEFAULT_NAMESPACE};

    #[abi(embed_v0)]
    impl GameMockImpl of super::IGameMock<ContractState> {
        fn start_game(ref self: ContractState, game_id: u64) {
            let mut world = self.world(@DEFAULT_NAMESPACE());
            let mut store: Store = StoreTrait::new(world);

            store.set_score(@Score { game_id, score: 0 });
        }

        fn end_game(ref self: ContractState, game_id: u64, score: u32) {
            let mut world = self.world(@DEFAULT_NAMESPACE());
            let mut store: Store = StoreTrait::new(world);
            store.set_score(@Score { game_id, score });
        }

        fn set_settings(
            ref self: ContractState,
            settings_id: u32,
            name: felt252,
            description: ByteArray,
            exists: bool,
        ) {
            let mut world = self.world(@DEFAULT_NAMESPACE());
            let mut store: Store = StoreTrait::new(world);
            store
                .set_settings_details(
                    @SettingsDetails { id: settings_id, name, description, exists: true },
                );
        }
    }
}