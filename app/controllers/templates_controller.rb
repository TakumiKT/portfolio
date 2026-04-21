class TemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: %i[show edit update destroy]

  before_action :authenticate_user!

  def index
    @templates = current_user.templates.order(:name)
    @template  = current_user.templates.new
  end

  def show; end

  def new
    @template = current_user.templates.new
  end

  def create
    @template = current_user.templates.new(template_params)
    if @template.save
      redirect_to templates_path, notice: "テンプレートを作成しました。"
    else
      @templates = current_user.templates.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @template.update(template_params)
      redirect_to templates_path, notice: "テンプレートを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy!
    redirect_to templates_path, notice: "テンプレートを削除しました。"
  end

  private

  def set_template
    @template = current_user.templates.find(params[:id])
  end

  def template_params
    params.require(:template).permit(
      :name,
      :symptom_hint, :check_point_hint, :judgment_hint,
      :concern_point_hint, :reflection_hint,
      #:tag_names_hint
    )
    @memo.tag_names = t.tag_names_hint if t.respond_to?(:tag_names_hint)
  end
end
