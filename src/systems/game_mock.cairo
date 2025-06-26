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
pub mod game_mock {
    use dojo::{
        event::EventStorage, model::ModelStorage,
        world::{IWorldDispatcher, IWorldDispatcherTrait, WorldStorage, WorldStorageTrait},
    };

    use tournaments::components::{
        game::game_component, 
        interfaces::{WorldImpl, IGameDetails, IGameToken, ISettings},
        libs::{
            game_store::{Store, StoreTrait},
            lifecycle::{LifecycleAssertionsImpl, LifecycleAssertionsTrait},
        },
        models::{
            game::{SettingsDetails, Score, TokenMetadata}, 
            lifecycle::Lifecycle,
        },
    };

    use openzeppelin_token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};

    use dojo_starter::{
        constants::{DEFAULT_NAMESPACE},
        models::game::{Game, GameActionEvent, GameOwnerTrait, GameOwnerImpl},
    };

    #[abi(embed_v0)]
    impl GameMockImpl of super::IGameMock<ContractState> {
        fn start_game(ref self: ContractState, game_id: u64) {
            let mut world = self.world(@DEFAULT_NAMESPACE());
            let mut store: Store = StoreTrait::new(world);

            let token_metadata: TokenMetadata = world.read_model(game_id);
            self.validate_start_conditions(game_id, @token_metadata);

            let mut game = Game { game_id, score: 0 };
            world.write_model(@game);
            store.set_score(@Score { game_id, score: 0 });

            // world
            //     .emit_event(
            //         @GameActionEvent {
            //             game_id, tx_hash: starknet::get_tx_info().unbox().transaction_hash,
            //             count: 0,
            //         },
            //     );

            // Emit initial metadata update
            let game: Game = self.world(@DEFAULT_NAMESPACE()).read_model(game_id);
            game.update_metadata(world);
        }

        fn end_game(ref self: ContractState, game_id: u64, score: u32) {
            let mut world = self.world(@DEFAULT_NAMESPACE());
            let mut store: Store = StoreTrait::new(world);

            let token_metadata: TokenMetadata = world.read_model(game_id);
            token_metadata.lifecycle.assert_is_playable(game_id, starknet::get_block_timestamp());

            store.set_score(@Score { game_id, score });

            // Emit metadata update after game ends
            let game: Game = self.world(@DEFAULT_NAMESPACE()).read_model(game_id);
            game.update_metadata(self.world(@DEFAULT_NAMESPACE()));
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

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        #[inline(always)]
        fn validate_start_conditions(self: @ContractState, token_id: u64, token_metadata: @TokenMetadata) {
            self.assert_token_ownership(token_id);
            self.assert_game_not_started(token_id);
            token_metadata.lifecycle.assert_is_playable(token_id, starknet::get_block_timestamp());
        }

        #[inline(always)]
        fn assert_token_ownership(self: @ContractState, token_id: u64) {
            let world = self.world(@DEFAULT_NAMESPACE());
            let (contract_address, _) = world.dns(@"game_token").unwrap();
            let game_token = IERC721Dispatcher { contract_address };
            assert!(
                game_token.owner_of(token_id.into()) == starknet::get_caller_address(), 
                "Caller {:?} is not Owner of token {}. Owner is {:?}",
                starknet::get_caller_address(),
                token_id,
                game_token.owner_of(token_id.into()),
            );
        }

        #[inline(always)]
        fn assert_game_not_started(self: @ContractState, game_id: u64) {
            let game: Game = self.world(@DEFAULT_NAMESPACE()).read_model((game_id));
            assert!(!game.exists(), "Dojo Starter: Game {} has already started", game_id);
        }
    }
}
