# frozen_string_literal: true

class PostLocalizationsController < ApplicationController
  before_action :ensure_logged_in

  def create
    guardian.ensure_can_localize_content!

    params.require(%i[post_id locale raw])
    PostLocalizationCreator.create(
      post_id: params[:post_id],
      locale: params[:locale],
      raw: params[:raw],
      user: current_user,
    )
    render json: success_json, status: :created
  end

  def update
    guardian.ensure_can_localize_content!

    params.require(%i[post_id locale raw])
    PostLocalizationUpdater.update(
      post_id: params[:post_id],
      locale: params[:locale],
      raw: params[:raw],
      user: current_user,
    )
    render json: success_json, status: :ok
  end

  def destroy
    guardian.ensure_can_localize_content!

    params.require(%i[post_id locale])
    PostLocalizationDestroyer.destroy(
      post_id: params[:post_id],
      locale: params[:locale],
      acting_user: current_user,
    )
    head :no_content
  end
end
