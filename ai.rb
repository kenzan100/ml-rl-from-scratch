TicTacToeLabel = :tic_tac_toe

class Ai
  attr_reader :world, :playable_worlds, :step_size, :my_side
  attr_accessor :values

  def initialize(world:, learned_values_path: nil)
    @playable_worlds = [TicTacToeLabel]
    @world = world
    @step_size = 0.1
    @my_side = 'o'
    check_playability!

    if learned_values_path
      File.open(learned_values_path, 'rb') do |file| 
        self.values = Marshal.load file
      end
    else
      self.values = {}
    end
    @values.delete_if { |k, _v| k.nil? }
  end

  def start
    world_state = world.clone_state(world.reset)
    next_value = init_value(state: world_state)

    begin
      puts "Turn #{world.turn_num}"

      old_state = world.clone_state(world_state)
      old_value = next_value

      your_move = determine_move(state: old_state)
      world.step(move: your_move)

      break if world.ended?

      puts "Waiting your your input"
      puts world.to_s
      human_move_id = STDIN.gets
      human_move = world.parse_human_move(move_id: human_move_id,
                                          symbol: world.opposite_side(side: my_side))
      world_state = world.clone_state(world.step(move: human_move))

      # Re-Evaluate the values
      next_value = values[world_state] || init_value(state: world_state)
      new_value = old_value + (step_size * ( next_value - old_value ))
      values[old_state] = new_value

      pp values

    end while !world.ended?

    File.open("Ai_values.dump", 'wb') do |file|
      file.print Marshal.dump(values)
    end

    puts "RESULT"
    puts world.to_s
  end

  private

  def check_playability!
    raise "I don't know" unless playable_worlds.include?(world.label)
  end

  def init_value(state:)
    value = case
            when win?(state: state)
              1
            when lose?(state: state) || world.ended?
              0
            else
              0.5
            end
    values[state] = value
    value
  end

  def win?(state:)
    world.won?(side: my_side)
  end

  def lose?(state:)
    world.won?(side: world.opposite_side(side: my_side))
  end

  def determine_move(state:)
    pp world.next_possible_moves_states.map { |ms| values[ms[:state]] }

    next_move_state_greedy = world.next_possible_moves_states.max_by do |move_and_state|
      state = move_and_state[:state]
      values[state] || init_value(state: state)
    end
    pp next_move_state_greedy

    next_move_state_greedy[:move]
  end
end
