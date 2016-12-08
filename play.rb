require 'pp'
require 'byebug'

require_relative 'tic_tac_toe'
require_relative 'ai'

world = TicTacToe.new
ai = Ai.new(world: world, learned_values_path: ARGV[0])
ai.start
