# app/models/user.rb
class User < ApplicationRecord
  has_many :pixels

  def pixels_drawn_in_time_frame(time_frame)
    scope = pixels
    case time_frame
    when "today"
      scope = scope.where("created_at >= ?", Time.current.beginning_of_day)
    when "month"
      scope = scope.where("created_at >= ?", Time.current.beginning_of_month)
    when "year"
      scope = scope.where("created_at >= ?", Time.current.beginning_of_year)
    end
    scope.count
  end
end
