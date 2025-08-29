class Grapher

  STEPS = 36 unless defined? STEPS

  def Grapher.years
    hash = {}

    Fake.all.each do |fake|
      next if fake.date.nil?
      year = fake.date.year
      hash[ year ] = 0 if hash[ year ].nil?
      hash[ year ] += 1
    end

    keys = hash.keys.sort
    all_years = Grapher.fill_in_years( keys )
    years = {}
    all_years.each { |year| years[ year.to_s[ -2 .. -1 ] ] = hash[ year ].nil?? 0 : hash[ year ] }

    years
  end

  def Grapher.months
    array = Grapher.all_year_months

    hash = {}
    array.each { |item| hash[ item ] = 0 }
    fakes = Fake.order( :date )

    fakes.each do |fake|
      next if fake.date.nil?
      year_month = Grapher.year_month( fake.date.year, fake.date.month )
      next if hash[ year_month ].nil?
      hash[ year_month ] += 1
    end

    keys = hash.keys
    keys = keys[ -STEPS .. -1 ] if keys.size > STEPS
    new_hash = {}
    keys.each { |key| new_hash[ key ] = hash[ key ] }
    keys = []
    values = new_hash.values
    new_hash.each { |key, val| keys << Grapher.split_year_month( key ) }

    return keys, values
  end

  private
  def Grapher.year_month( year, month ) # For sorting
    "#{year}#{"%02d" % month}".to_i # August 1979 -> 197908
  end

  def Grapher.split_year_month( year_month ) # For displaying
    month_year = year_month.to_s
    month = month_year[ -2 .. - 1 ]
    month = month[ -1 .. -1 ] if month[ -2 ] == '0'
    month = Date::MONTHNAMES[ month.to_i ]
    "#{ month[ 0 .. 2 ] } #{ month_year[ 2 .. 3 ] }" # 197908 -> 'Aug 79'
  end

  def Grapher.number_of_hoaxes_in_month( fakes, year, month )
    fakes.each         { |fake| fake.delete if fake.date.nil? }
    arr = fakes.select { |fake| fake.date.year == year && fake.date.month == month }
    arr.size
  end

  def Grapher.all_year_months_in_which_more_than_two_hoaxes_happened( fakes )
    fakes.each      { |fake| fake.delete if Grapher.number_of_hoaxes_in_month( fakes, fake.date.year, fake.date.month ) < 3 }
    fakes.collect   { |fake| Grapher.year_month( fake.date.year, fake.date.month ) }
  end

  def Grapher.all_year_months # All the recent months excluding the present one in which > 2 hoax happened
    fakes = Fake.order( :date )
    fakes.each { |fake| fake.delete if fake.date.nil? }
    active_year_months = Grapher.all_year_months_in_which_more_than_two_hoaxes_happened fakes
    array = []
    last = fakes.last
    min = fakes.first.date.year.to_i
    max = last.date.year.to_i
    (min..max).each do |year|
      (1..12).each do |month|
        break if year == max && month > last.date.month - 1
        year_month = Grapher.year_month( year, month ) # August 1979 -> 197908
        array << year_month if active_year_months.include? year_month
      end
    end

    array.uniq
  end

  def Grapher.fill_in_years( array ) # Fill in missing years
    min = array.min
    max = array.max
    new_array = []
    unless min.nil? || max.nil?
      (min..max).each { |item| new_array << item }
    end
    new_array
  end

end
