module Generic

  def user_name( u )
    ((u and self.user_id != u.id and u.admin?)? "(#{ self.user.name })" : '' )
  end

  def date_format date # October 3, 2015
    return date if date.blank?
    return date if date.is_a? String
    day = date.strftime( '%e' ).strip
    month = date.strftime( '%B' )
    year = date.strftime( '%Y' )
    month + ' ' + day + ', ' + year
  end

  def get(attribute)
    self.attributes[attribute.to_s]
  end

end
