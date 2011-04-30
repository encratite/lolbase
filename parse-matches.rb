require 'nil/file'
require 'nil/symbol'
require 'nil/string'

class ChampionPerformance
  Symbols = [
             :name,
             :kills,
             :deaths,
             :assists,
             :minionsSlain,
             :barracksDestroyed,
             :turretsDestroyed,
             :neutralMonstersSlain,
             :physicalDamageDealt,
             :magicalDamageDealt,
             :largestCriticalStrike,
             :largestKillingSpree,
             :largestMultiKill,
             :physicalDamageTaken,
             :magicalDamageTaken,
             :healthRestored,
             :gold,
             :timeSpentDead
            ]
  attr_reader(*Symbols)

  attr_reader :count

  attr_writer :victories, :defeats

  include SymbolicAssignment

  def initialize
    @count = 1
    @victories = 0
    @defeats = 0
  end

  def accumulate(other)
    targets = Symbols + [:victories, :defeats]
    targets.each do |symbol|
      symbol = ('@' + symbol.to_s).to_sym
      value = instance_variable_get(symbol)
      if [Fixnum, Float].include?(value.class)
        otherValue = other.instance_variable_get(symbol)
        if otherValue == nil
          puts "nil symbol: #{other.inspect}"
        end
        newValue = value + otherValue
        instance_variable_set(symbol, newValue)
      end
    end
    @count += 1
  end

  def killDeathRatio
    return @kills.to_f / @deaths
  end

  def winLossRatio
    return @victories.to_f / @defeats
  end

  def averageGold
    return @gold.to_f / @count
  end

  def averageMinionKills
    return @minionsSlain.to_f / @count
  end

  def fixName
    translations = {
      'Voidwalker' => 'Kassadin',
      'Jester' => 'Shaco',
      'Cryophoenix' => 'Anivia',
      'MissFortune' => 'Miss Fortune',
      'Lich' => 'Karthus',
      'KogMaw' => "Kog'Maw",
      'Pirate' => 'Gangplank',
      'Bowmaster' => 'Ashe',
      'MasterYi' => 'Master Yi',
      'GreenTerror' => "Cho'Gath",
      'DarkChampion' => 'Tryndamere',
      'JarvanIV' => 'Jarvan IV',
      'Wolfman' => 'Warwick',
      'CardMaster' => 'Twisted Fate',
      'Chronokeeper' => 'Zilean',
      'DrMundo' => 'Dr. Mundo',
      'FallenAngel' => 'Morgana',
      'XenZhao' => 'Xin Zhao',
      'SteamGolem' => 'Blitzcrank',
      'Judicator' => 'Kayle',
      'ChemicalMan' => 'Singed',
      'SadMummy' => 'Amumu',
      'Armordillo' => 'Rammus',
      'Armsmaster' => 'Jax',
      'Yeti' => 'Nunu',
      'GemKnight' => 'Taric',
      'Minotaur' => 'Alistar',
      'FiddleSticks' => 'Fiddlesticks',
    }
    translation = translations[@name]
    if translation != nil
      @name = translation
    end
  end

  def processOutcome(isWinner)
    if isWinner
      @victories += 1
    else
      @defeats += 1
    end
  end
end

class Statistics
  attr_reader :championCount

  def initialize(path)
    @champions = {}
    @championCount = 0
    loadMatches(path)
  end

  def loadMatches(path)
    testingLimit = nil
    #testingLimit = 100
    targets = Nil.readDirectory(path)
    counter = 1
    targets.each do |target|
      path = target.path
      if path.index('(') != nil
        next
      end
      path = path.gsub('/', '\\')
      #puts "Processing #{path} (#{counter}/#{targets.size})"
      markup = Nil.readFile(path)
      parseMarkup(markup)
      counter += 1
      if testingLimit != nil && counter >= testingLimit
        break
      end
    end
  end

  def parseMarkup(markup)
    if markup.index('2011-') == nil
      return
    end
    typeMatch = markup.match(/>Type: (.+?)</)
    if typeMatch == nil
      raise "Unable to determine the type of the match"
    end
    type = typeMatch[1]
    if type != 'RANKED_SOLO_5x5'
      return
    end
    winOffset = markup.index('Winning Team')
    loseOffset = markup.index('Losing Team')
    if [winOffset, loseOffset].include?(nil)
      raise 'Unable to determine the winning/losing team order'
    end
    isWinner = winOffset < loseOffset
    pattern = /src="http:\/\/www.lolbase.net\/images\/champions\/icons\/small\/(.+?)\.png".*?<td>Kills:<\/td>.*?<th>(\d+)<\/th>.*?<td>Deaths:<\/td>.*?<th>(\d+)<\/th>.*?<td>Assists:<\/td>.*?<th>(\d+)<\/th>.*?<td>Minions slain:<\/td>.*?<th>(\d+)<\/th>.*?<td>Barracks destroyed:<\/td>.*?<th>(\d+)<\/th>.*?<td>Turrets destroyed:<\/td>.*?<th>(\d+)<\/th>.*?<td>Neutral monsters slain:<\/td>.*?<th>(\d+)<\/th>.*?<td>Physical damage dealt:<\/td>.*?<th>(\d+)<\/th>.*?<td>Magic damage dealt:<\/td>.*?<th>(\d+)<\/th>.*?<td>Largest critical strike:<\/td>.*?<th>(\d+)<\/th>.*?<td>Largest killing spree:<\/td>.*?<th>(\d+)<\/th>.*?.*?<td>Largest multi kill:<\/td>.*?<th>(\d+)<\/th>.*?<td>Physical damage taken:<\/td>.*?<th>(\d+)<\/th>.*?<td>Magic damage taken:<\/td>.*?<th>(\d+)<\/th>.*?<td>Health restored:<\/td>.*?<th>(\d+)<\/th>.*?<td>Gold:<\/td>.*?<th>(\d+)<\/th>.*?<td>Time spent dead:<\/td>.*?<th>(.*?)<\/th>/m
    teamSize = 5
    offset = 0
    markup.scan(pattern) do |match|
      champion = ChampionPerformance.new
      match.size.times do |i|
        symbol = ChampionPerformance::Symbols[i]
        value = match[i]
        #puts "#{symbol}: #{value}"
        if value.isNumber
          value = value.to_i
        end
        champion.setMember(symbol, value)
      end
      champion.fixName
      champion.processOutcome(isWinner)
      key = champion.name
      if @champions[key] == nil
        @champions[key] = champion
      else
        @champions[key].accumulate(champion)
      end
      @championCount += 1
      offset += 1
      if offset == teamSize
        isWinner = !isWinner
      end
    end
    if offset != teamSize * 2
      raise "Invalid number of matched champions: #{offset}"
    end
  end

  def sortByFunction(function)
    champions = @champions.values.sort do |x, y|
      - (function.call(x) <=> function.call(y))
    end
    return champions
  end

  def floatingPoint(input)
    return sprintf('%.2f', input)
  end

  def printList(champions)
    counter = 1
    champions.each do |champion|
      puts "#{counter}. #{champion.name}: KDR #{floatingPoint champion.killDeathRatio}, WLR #{floatingPoint champion.winLossRatio}, gold #{floatingPoint champion.averageGold}, minion kills #{floatingPoint champion.averageMinionKills}, popularity #{floatingPoint(champion.count.to_f / @championCount * 100)}%"
      counter += 1
    end
  end

  def sortAndPrint(title, &function)
    puts "#{title}:"
    champions = sortByFunction(function)
    printList(champions)
    puts ''
  end
end

statistics = Statistics.new('data/matches')
statistics.sortAndPrint('Kill/death ratio') { |x| x.killDeathRatio }
statistics.sortAndPrint('Win/loss ratio') { |x| x.winLossRatio }
statistics.sortAndPrint('Gold') { |x| x.averageGold }
statistics.sortAndPrint('Minion kills') { |x| x.averageMinionKills }
statistics.sortAndPrint('Popularity') { |x| x.count }
puts "Total number of samples: #{statistics.championCount}"
