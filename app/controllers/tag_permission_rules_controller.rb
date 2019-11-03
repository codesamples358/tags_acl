class TagPermissionRulesController < ApplicationController
  before_action :find_rule, except: [:new, :destroy, :create]

  def new
    @rule = TagPermissionRule.new(name: 'New rule')
  end

  def create
    @rule = TagPermissionRule.new(rule_params)

    if @rule.save
      redirect_to(controller: 'settings', action: 'plugin', id: 'tags_acl')
    else
      render :action => :new
    end
  end

  def edit
    @rule = TagPermissionRule.find(params[:id])
  end

  def update
    if @rule.update_attributes(rule_params)
      redirect_to(controller: 'settings', action: 'plugin', id: 'tags_acl')
    else
      render :action => :new
    end
  end

  def destroy
    all_records = TagPermissionRule.where(id: params[:ids])
    all_records.each(&:destroy)

    redirect_to(controller: 'settings', action: 'plugin', id: 'tags_acl')
  end

  def find_rule
    @rule = TagPermissionRule.find(params[:id])
  end

  def rule_params
    params.require(:tag_permission_rule).permit(:name, :role_id, :role_not, :tag_not, :tag_list, :tag)
  end
end
