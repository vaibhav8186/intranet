module RestfulAction
  extend ActiveSupport::Concern

  def update_obj(model_obj, params, redirect_path)
    if model_obj.update_attributes(params)
      flash[:success] = "#{model_obj.class.to_s} updated Succesfully" 
      redirect_to redirect_path
    else
      flash[:error] = "#{model_obj.class.to_s}: #{model_obj.errors.full_messages.join(',')}" 
      render 'edit'
    end
  end
end
