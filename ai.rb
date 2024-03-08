class DotsBoxes
  attr_accessor :rows, :columns, :play_dict, :score_dict
  attr_accessor :a_score, :b_score
  def initialize(rows, columns)
    @rows = rows
    @columns = columns

    @play_dict = {}
    rows.times do |row|
      (columns-1).times do |column|
        @play_dict[[column+(row*columns), column+(row*columns)+1]] = 0
      end
    end

    (rows-1).times do |row|
      (columns).times do |column|
        @play_dict[[column+(row*columns), column+columns+(row*columns)]] = 0
      end
    end

    @score_dict = {}
    rows.times do |row|
      columns.times do |column|
        box = [[column + (row*columns), column+(row*columns)+1]]
        box << [box[0][0], box[0][1] + columns-1]
        box << [box[0][0] +1, box[0][1] + columns]
        box << [box[0][0] + columns, box[2][1]]
        @score_dict[box] = 0
      end
    end

    @a_score = 0
    @b_score = 0
  end

  def render_row(row_number)
    left = row_number * columns
    right = left + 1
    str_row = ""

    (columns-1).times do
      if play_dict[[left,right]].eql?(0)
        str_row << sprintf("%3d", left) << "   "
      else
        str_row << sprintf("%3d", left) << " - "
      end
      left = right
      right = left + 1
    end
    str_row << " #{left} "
    puts str_row
  end

  def render_vertical(upper_left, upper_right)
    str_vertical = ""
    if play_dict[[upper_left, upper_right]].eql?(0)
      str_vertical << "   "
    else
      str_vertical << " | "
    end

    return str_vertical
  end

  def render_middle_row(row_number)
    upper_left = row_number * columns
    upper_right = upper_left + 1
    bottom_left = upper_left + columns
    bottom_right = bottom_left + 1
    str_middle_row = ""
    str_vertical = ""

    columns.times do
      str_vertical = render_vertical(upper_left, upper_right)

      top = [upper_left, upper_right]
      left = [upper_left, bottom_left]
      right = [upper_right, bottom_right]
      bottom = [bottom_left, bottom_right]

      score = score_dict[[top, left, right, bottom]]

      if score.eql?(0)
        str_middle_row << "  "
      else
        str_middle_row << " " + score + " "
      end

      upper_left, bottom_left = upper_right, bottom_right
      upper_right += 1
      bottom_right += 1
    end

    puts str_middle_row
    render_vertical(upper_left, bottom_left)
  end

  def render
    rows.times do |row_number|
      #puts "Iteration #{row_number}"
      render_row(row_number)
      render_middle_row(row_number)
    end

    #puts "Score dict: #{score_dict}\n\nPlay dict: #{play_dict}"
  end

  def check_scores(player_a)
    player = player_a ? "A" : "B"

    taken_set = []
    open_scores = []

    play_dict.each do |pair|
      #puts play_dict[pair]
      if play_dict[pair].eql?(0)
        taken_set << pair
      end
    end

    score_dict.each do |element|
      if score_dict[element].eql?(0)
        open_scores << element
      end
    end

    score_counter = 0

    open_scores.each do |open|
      if taken_set.contains(open)
        score_counter += 1
        score_dict[open] = player_a
      end
    end

    return score_counter
    #puts taken_set.inspect
  end

  def make_play(start_point, end_point, player)
    if play_dict[[start_point, end_point]].eql?(1)
      return false
    end

    play_dict[[start_point, end_point]] = 1
    score = check_scores(player)

    if player.eql?("A")
      a_score = a_score.to_i + score
    else
      b_score = b_score.to_i + score
    end

    return true
  end

  def get_open_plays
    open_plays = []
    play_dict.each do |play|
      if play_dict[play].eql?(0)
        open_plays << play
      end
    end
    return open_plays
  end

  def is_over
    return (a_score + b_score).eql?(score_dict.length)
  end
end

class HumanPlayer
  attr_accessor :player
  def initialize(player)
    @player = player
  end

  def make_play(game)
    while true
      puts "Escribe tu jugada de la siguiente forma (Punto_inicio Punto_final): "
      play = gets.chomp.split(" ").map {|point| point.to_i}

      valid_play = game.make_play(*play, player)
      if valid_play
        puts "Jugada valida"
      end
    end
  end
end

class AlphaBetaPlayer
  attr_reader :player

  def initialize(player_a)
    @player = player_a
  end

  def alphabeta(game, play, depth, alpha, beta, player_a)
    return (game.current_player_score(@player) - game.current_player_score(!@player), play) if game.is_over || depth == 0

    value = player_a ? -Float::INFINITY : Float::INFINITY
    game.get_open_plays.each do |move|
      new_game = game.dup  # Deep copy of the game state
      old_score = game.current_player_score(player_a)
      new_game.make_play(*move, player_a)
      new_score = game.current_player_score(player_a)

      if new_score == old_score
        new_play_results = alphabeta(new_game, move, depth - 1, alpha, beta, !player_a)
      else
        new_play_results = alphabeta(new_game, move, depth - 1, alpha, beta, player_a)
      end

      if player_a
        value = [value, new_play_results[0]].max
        alpha = [alpha, value].max
      else
        value = [value, new_play_results[0]].min
        beta = [beta, value].min
      end

      break if beta <= alpha
    end

    return value, play
  end

  def make_play(game)
    start_time = Time.now

    play_space_size = game.get_open_plays.size
    play = game.get_open_plays.sample if play_space_size == 1
    game.make_play(*play, @player) if play

    depth = Math.log(19000, play_space_size).floor

    play = alphabeta(game, (0, 0), depth, -Float::INFINITY, Float::INFINITY, @player)[1]
    elapsed = Time.now - start_time

    play = game.get_open_plays.sample unless play  # Fallback random move

    game.make_play(*play, @player)

    player_name = @player ? 'A' : 'B'
    puts "Player #{player_name}'s move: #{play[0]}, #{play[1]}"
    puts "Time elapsed to make move: #{elapsed}"
  end
end

class Game
  attr_accessor :player_a, :player_b, :rows, :columns
  def initialize(player_a, player_b, rows=5, columns=5)
    @player_a = player_a
    @player_b = player_b
    @rows = rows
    @columns = columns
  end

  def play_game
    game = DotsBoxes.new(rows, columns)
    game.render()
    game.check_scores(player_a)
    player = HumanPlayer.new("A")
    player.make_play(game)
  end
end

puts "Ingresa la cantidad de filas"
game_rows = gets.chomp.to_i
puts "Ingresa la cantidad de columnas"
game_columns = gets.chomp.to_i

game = Game.new("A", "B", game_rows, game_columns)
game.play_game
