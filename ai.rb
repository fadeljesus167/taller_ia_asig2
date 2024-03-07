class DotsBoxes
  attr_accessor :rows, :columns, :play_dict, :score_dict
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
    play_dict.each do |pair|
      puts play_dict[pair]
      if play_dict[pair].eql?(0)
        taken_set << pair
      end
    end
    puts taken_set.inspect
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
  end
end

puts "Ingresa la cantidad de filas"
game_rows = gets.chomp.to_i
puts "Ingresa la cantidad de columnas"
game_columns = gets.chomp.to_i

game = Game.new("Fadel", "AI", game_rows, game_columns)
game.play_game
