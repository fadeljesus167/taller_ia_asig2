class Object
  def deep_clone
    Marshal::load(Marshal::dump(self))
  end
end

class DotsBoxes
  attr_accessor :rows, :columns, :play_dict, :score_dict, :a_score, :b_score

  def initialize(rows, columns)
    @a_score = 0
    @b_score = 0
    @rows = rows
    @columns = columns

    @play_dict = {}
    rows.times do |row|
      (columns-1).times do |column|
        @play_dict[[column+(row*columns), column+(row*columns)+1]] = 0
      end
    end

    (rows-1).times do |row|
      columns.times do |column|
        @play_dict[[column+(row*columns), column+columns+(row*columns)]] = 0
      end
    end

    @score_dict = {}
    (rows-1).times do |row|
      (columns-1).times do |column|
        box = [[column + (row*columns), column+(row*columns)+1]]
        box << [box[0][0], box[0][1] + columns-1]
        box << [box[0][0] +1, box[0][1] + columns]
        box << [box[0][0] + columns, box[2][1]]
        @score_dict[box] = 0
      end
    end
  end

  def render_row(row_number)
    left = row_number * columns
    right = left + 1
    str_row = ""

    (columns-1).times do
      if play_dict[[left,right]].eql?(0)
        str_row << sprintf("%3d", left) << "   "
      else
        str_row << sprintf("%3d -", left) << " "
      end
      left = right
      right = left + 1
    end
    str_row << sprintf("%3d", left)
    puts str_row
  end

  def render_vertical(upper_left, bottom_left)
    if play_dict[[upper_left, bottom_left]] == 0
      print("   ")
    else
      print("  |")
    end
  end

  def render_middle_row(row_number)
    upper_left = row_number * columns
    upper_right = upper_left + 1
    bottom_left = upper_left + columns
    bottom_right = bottom_left + 1
    str_middle_row = ""
    str_vertical = ""

    (columns-1).times do
      render_vertical(upper_left, bottom_left)

      top = [upper_left, upper_right]
      left = [upper_left, bottom_left]
      right = [upper_right, bottom_right]
      bottom = [bottom_left, bottom_right]

      score = score_dict[[top, left, right, bottom]]
      if score.eql?(0)
        print ("   ")
      else
        print (" " + score + " ")
      end

      upper_left, bottom_left = upper_right, bottom_right
      upper_right += 1
      bottom_right += 1
    end

    render_vertical(upper_left, bottom_left)
    puts
  end

  def render
    (rows-1).times do |row_number|
      render_row(row_number)
      render_middle_row(row_number)
    end
    render_row(rows-1)
    puts
  end

  def check_scores(player)
    taken_set = play_dict.select { |i| @play_dict[i] == 1 }.keys.to_set
    open_scores = score_dict.select { |i| @score_dict[i] == 0 }.keys.to_a


    score_counter = 0
    open_scores.each do |box|
      if box.to_set.subset?(taken_set)
        score_counter += 1
        @score_dict[box] = player
      end
    end
    score_counter
  end

  def make_play(start_point, end_point, player)
    if play_dict[[start_point, end_point]].eql?(1)
      return false
    end

    play_dict[[start_point, end_point]] = 1
    score = check_scores(player)
    if player.eql?("A")
      @a_score = a_score.to_i + score.to_i
    else
      @b_score = b_score.to_i + score.to_i
    end
    return true
  end

  def get_open_plays
    open_plays = []
    play_dict.each do |play|
      if play_dict[play[0]].eql?(0)
        open_plays << play[0]
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
        puts "Jugador #{player} jugo: #{play[0]}, #{play[1]}"
        break;
      else
        puts "Ya hiciste esa jugada"
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
    if game.is_over() || depth == 0
      return [game.a_score - game.b_score, play]
    end
    if player_a.eql?("A")
      value = -Float::INFINITY
      game.get_open_plays().each do |move|
        new_game = game.deep_clone
        old_score = new_game.a_score
        new_game.make_play(*move, "A")
        new_score = new_game.a_score
        if new_score == old_score
          new_play_results = alphabeta(new_game, move, depth - 1, alpha, beta, "B")
        else
          new_play_results = alphabeta(new_game, move, depth - 1, alpha, beta, "A")
        end
        if value >= new_play_results[0]
          play = move
          value = new_play_results[0]
        end
        alpha = [alpha, value].max
        if alpha >= beta
          break
        end
      end
      return [value, play]
    else
      value = Float::INFINITY
      game.get_open_plays().each do |move|
        new_game = game.deep_clone
        old_score = new_game.b_score
        new_game.make_play(*move, "B")
        new_score = new_game.b_score
        if new_score == old_score
          move_results = alphabeta(new_game, move, depth - 1, alpha, beta, "A")
        else
          move_results = alphabeta(new_game, move, depth - 1, alpha, beta, "B")
        end
        if value <= move_results[0]
          play = move
          value = move_results[0]
        end
        beta = [beta, value].min
        if beta <= alpha
          break
        end
      end
      return [value, play]
    end
  end

  def make_play(game)
    play_space_size = game.get_open_plays.size
    if play_space_size == 1
      play = game.get_open_plays.sample
      game.make_play(*play, player) if play

      return
    end

    depth = Math.log(19000, play_space_size).floor
    play = alphabeta(game, [0, 0], depth, -Float::INFINITY, Float::INFINITY, player)[1]
    play = game.get_open_plays.sample if play.eql?([0,0])  # Fallback random move

    game.make_play(*play, player)

    puts "Jugador #{player} jugo: #{play[0]}, #{play[1]}"
  end
end

class Game
  attr_accessor :player_a, :player_b, :rows, :columns
  def initialize(player_a, player_b, rows=5, columns=5)
    @player_a = HumanPlayer.new(player_a)
    @player_b = AlphaBetaPlayer.new(player_b)
    @rows = rows
    @columns = columns
  end

  def play_game
    game = DotsBoxes.new(rows, columns)
    turno = ""

    while true
      puts "Desea comenzar usted? (s/n)"
      resp = gets.chomp.downcase
      if resp.eql?("s") || resp.eql?("n")
        turno = resp.eql?("s") ? "A" : "B"
        break
      end
    end

    game.render

    while(!game.is_over)
      while(!game.is_over && turno.eql?("A"))
        old_score = game.a_score
        @player_a.make_play(game)
        game.render
        if old_score.eql?(game.a_score)
          turno = "B"
          break;
        end
      end

      while(!game.is_over && turno.eql?("B"))
        old_score = game.b_score
        @player_b.make_play(game)
        game.render
        if old_score.eql?(game.b_score)
          turno = "A"
          break;
        end
      end
    end

    puts game.a_score.eql?(game.b_score) ? "Empate" : (game.a_score > game.b_score) ? "Gana A" : "Gana B"
  end
end

def main
  puts "Ingresa la cantidad de filas"
  game_rows = gets.chomp.to_i
  puts "Ingresa la cantidad de columnas"
  game_columns = gets.chomp.to_i

  game = Game.new("A", "B", game_rows, game_columns)
  game.play_game
end

main
