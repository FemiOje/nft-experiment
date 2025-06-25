#[cfg(test)]
mod tests {
    use dojo_cairo_test::WorldStorageTestTrait;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    };

    use dojo_starter::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use dojo_starter::systems::game_mock::{game_mock, IGameMockDispatcher, IGameMockDispatcherTrait};
    use dojo_starter::systems::game_token::{game_token, IGameTokenSystemsDispatcher, IGameTokenSystemsDispatcherTrait};
    use dojo_starter::models::{Position, m_Position, Moves, m_Moves, Direction};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_Position::TEST_CLASS_HASH),
                TestResource::Model(m_Moves::TEST_CLASS_HASH),
                TestResource::Event(actions::e_Moved::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(game_mock::TEST_CLASS_HASH),
                TestResource::Contract(game_token::TEST_CLASS_HASH),

                TestResource::Model(
                    tournaments::components::models::game::m_GameMetadata::TEST_CLASS_HASH.try_into().unwrap(),
                ),
                TestResource::Model(
                    tournaments::components::models::game::m_TokenMetadata::TEST_CLASS_HASH.try_into().unwrap(),
                ),
                TestResource::Model(
                    tournaments::components::models::game::m_GameCounter::TEST_CLASS_HASH.try_into().unwrap(),
                ),
                TestResource::Model(tournaments::components::models::game::m_Score::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(tournaments::components::models::game::m_Settings::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(
                    tournaments::components::models::game::m_SettingsDetails::TEST_CLASS_HASH.try_into().unwrap(),
                ),
                TestResource::Model(
                    tournaments::components::models::game::m_SettingsCounter::TEST_CLASS_HASH.try_into().unwrap(),
                ),
                TestResource::Event(achievement::events::index::e_TrophyCreation::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(achievement::events::index::e_TrophyProgression::TEST_CLASS_HASH.try_into().unwrap()),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"dojo_starter", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span()),
            ContractDefTrait::new(@"dojo_starter", @"game_mock")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span()),
            ContractDefTrait::new(@"dojo_starter", @"game_token")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span())
                .with_init_calldata(array![starknet::contract_address_const::<'player1'>().into()].span()),
        ]
            .span()
    }

    #[test]
    fn test_world_test_set() {
        // Initialize test environment
        let caller = starknet::contract_address_const::<0x0>();
        let ndef = namespace_def();

        // Register the resources.
        let mut world = spawn_test_world([ndef].span());

        // Ensures permissions and initializations are synced.
        world.sync_perms_and_inits(contract_defs());

        // Test initial position
        let mut position: Position = world.read_model(caller);
        assert(position.vec.x == 0 && position.vec.y == 0, 'initial position wrong');

        // Test write_model_test
        position.vec.x = 122;
        position.vec.y = 88;

        world.write_model_test(@position);

        let mut position: Position = world.read_model(caller);
        assert(position.vec.y == 88, 'write_value_from_id failed');

        // Test model deletion
        world.erase_model(@position);
        let position: Position = world.read_model(caller);
        assert(position.vec.x == 0 && position.vec.y == 0, 'erase_model failed');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_move() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();
        let initial_moves: Moves = world.read_model(caller);
        let initial_position: Position = world.read_model(caller);

        assert(
            initial_position.vec.x == 10 && initial_position.vec.y == 10, 'wrong initial position',
        );

        actions_system.move(Direction::Right(()).into());

        let moves: Moves = world.read_model(caller);
        let right_dir_felt: felt252 = Direction::Right(()).into();

        assert(moves.remaining == initial_moves.remaining - 1, 'moves is wrong');
        assert(moves.last_direction.unwrap().into() == right_dir_felt, 'last direction is wrong');

        let new_position: Position = world.read_model(caller);
        assert(new_position.vec.x == initial_position.vec.x + 1, 'position x is wrong');
        assert(new_position.vec.y == initial_position.vec.y, 'position y is wrong');
    }
}
