class TagsController < ApplicationController
  before_action :authenticate_user!

  def autocomplete
    q = params[:q].to_s.strip

    tags = current_user.tags.order(:name) #自分のタグだけ
    if q.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
      tags = tags.where("name ILIKE ?", like)
    else
      tags = tags.none #空入力
    end

    render json: tags.limit(8).pluck(:name) #候補数を絞る（見やすさ重視）
  end
end