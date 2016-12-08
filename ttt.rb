require 'byebug'
require 'pp'

TicTacToeLabel = :tic_tac_toe

class TicTacToeState
  def init
  end
end

class TicTacToe
  attr_reader :state, :cur_turn_symbol, :turn_num
  def initialize
    @cur_turn_symbol = 'x'
    @turn_num = 1
  end

  def label
    TicTacToeLabel
  end

  def reset
    @state = [['-', '-', '-'],
              ['-', '-', '-'],
              ['-', '-', '-']]
    state
  end

  def parse_human_move(move_id:, symbol:)
    row = move_id[0].to_i
    col = move_id[1].to_i
    TicTacToeMove.new(row: row, column: col, playing_symbol: symbol)
  end

  def opposite_side(side:)
    side == 'o' ? 'x' : 'o'
  end

  def to_s
    rows = state.map { |row| row.join(' ') }
    rows.join("\n")
  end

  def step(move:)
    cur_symbol = @state[move.row][move.column]
    if cur_symbol != '-'
      byebug
      raise "Already occupied"
    end
    @state[move.row][move.column] = move.playing_symbol
    @cur_turn_symbol = cur_turn_symbol == 'o' ? 'x' : 'o'
    @turn_num += 1 if cur_turn_symbol == 'o'
    state
  end

  def virtual_step(move:)
    tmp_state = clone_state(state)
    tmp_state[move.row][move.column] = move.playing_symbol
    tmp_state
  end

  def clone_state(state)
    state.map { |row| row.clone }
  end

  def ended?
    same_mark_checker = -> (arr) { arr.all? { |mark| mark == 'o' } ||
                                   arr.all? { |mark| mark == 'x' } }
    check_end_condition(checker: same_mark_checker)
  end

  def won?(side:)
    one_side_mark_checker = -> (arr) { arr.all? { |mark| mark == side } }
    check_end_condition(checker: one_side_mark_checker)
  end

  def check_end_condition(checker:) 
    ended = [state.any? { |row| checker.call(row) },
             state.transpose.any? { |column| checker.call(column) },
             [0, 1, 2].map { |n| state[n] }.any? { |diagonal| checker.call(diagonal) },
             [2, 1, 0].map { |n| state[n] }.any? { |diagonal| checker.call(diagonal) }].any?
    ended
  end

  def next_possible_moves_states
    possible_moves_and_states = []
    state.each_with_index do |row, i|
      row.each_with_index do |cell, j|
        if cell == '-'
          move_and_state = {
            move: TicTacToeMove.new(row: i,
                                    column: j,
                                    playing_symbol: opposite_side(side: cur_turn_symbol))
          }
          move_and_state.merge!({ state: virtual_step(move: move_and_state[:move]) })
          possible_moves_and_states << move_and_state
        end
      end
    end
    possible_moves_and_states
  end
end

class TicTacToeMove
  attr_reader :row, :column, :playing_symbol
  def initialize(row:, column:, playing_symbol:)
    @row, @column, @playing_symbol = row, column, playing_symbol
  end
end

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

world = TicTacToe.new
ai = Ai.new(world: world, learned_values_path: ARGV[0])
ai.start
