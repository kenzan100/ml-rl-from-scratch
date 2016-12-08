require 'byebug'

TicTacToeLabel = :tic_tac_toe

class TicTacToe
  attr_reader :state
  def initialize
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

  def to_s
    rows = state.map { |row| row.join(' ') }
    rows.join("\n")
  end

  def step(move:)
    cur_symbol = @state[move.row][move.column] = move.playing_symbol
    raise "Already occupied" unless cur_symbol == '-'
    @state[move.row][move.column] = move.playing_symbol
    state
  end

  def virtual_step(move:)
    tmp_state = state.clone
    tmp_state[move.row][move.column] = move.playing_symbol
    tmp_state
  end

  def ended?
    same_mark_checker = -> (arr) { arr.all? { |mark| %w(o x).include?(mark) }  }
    [state.any? { |row| same_mark_checker.call(row) },
     state.change_axis.any? { |column| same_mark_checker.call(column) },
     [0, 1, 2].map { |n| state[n] }.any? { |diagonal| same_mark_checker.call(diagonal) },
     [2, 1, 0].map { |n| state[n] }.any? { |diagonal| same_mark_checker.call(diagonal) }].any?
  end

  def next_possible_moves_states
    possible_moves_and_states = []
    state.each_with_index do |row, i|
      row.each_with_index do |cell, j|
        if cell == '-'
          move_and_state = { move: TicTacToeMove.new(row: i, column: j, playing_symbol: cur_turn_symbol) }
          move_and_state.merge { state: virtual_step(move_and_state[:move]) }
          possible_moves_and_states << move_and_state
        end
      end
    end
    possible_moves_and_steps
  end
end

class TicTacToeMove
  attr_reader :row, :column, :playing_symbol
  def initialize(row:, column:, playing_symbol:)
    @row, @column, @playing_symbol = row, column, playing_symbol
  end
end

world = TicTacToe.new
world.reset
puts world.to_s

class Ai
  attr_reader :world, :playable_worlds
  attr_accessor :values

  def initialize(world:)
    @playable_worlds = [TicTacToeLabel]
    @world = world
    check_playability!
  end

  def start
    values = {}

    world_state = world.reset
    next_value = init_value(state: world_state)

    begin
      old_state = world_state
      old_value = next_value

      your_move = determine_move(state: old_state)

      world_state = world.step(move: your_move)

      next_value = values[world_state] || init_value(world_state)

      new_value = old_value + step_size( next_value - old_value )

      values[old_state] = new_value

    end while world.ended?
  end

  private

  def check_playability!
    raise "I don't know" unless playable_worlds.include?(world.label)
  end

  def init_value(state:)
    values[state] = 1 and return if win?(world: world, state: state)
    values[state] = 0 and return if lose?(world: world, state: state)
    values[state] = 0 and return if world.ended?
    values[state] = 0.5
  end

  def win?(state:)
  end

  def lose?(state:)
  end

  def determine_move(state:)
    next_move_state_greedy = world.next_possible_moves_states.max_by { |move_and_state| values[move_and_state[:state]] }
    next_move_state_greedy[:move]
  end
end
