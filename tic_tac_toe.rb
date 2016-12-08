TicTacToeLabel = :tic_tac_toe

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

  def won?(side:, tmp_state: nil)
    one_side_mark_checker = -> (arr) { arr.all? { |mark| mark == side } }
    check_end_condition(checker: one_side_mark_checker, tmp_state: tmp_state)
  end

  def check_end_condition(checker:, tmp_state: nil)
    state = tmp_state.nil? ? @state : tmp_state
    ended = [state.any? { |row| checker.call(row) },
             state.transpose.any? { |column| checker.call(column) },
             checker.call([0, 1, 2].map.with_index { |n,i| state[i][n] }),
             checker.call([2, 1, 0].map.with_index { |n,i| state[i][n] })].any?
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
