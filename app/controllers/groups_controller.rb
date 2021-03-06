class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]

  # GET /groups or /groups.json
  def index
    @filter = { game_id: params[:game_id] }
    params.each do |key, value|
      if key.end_with?('filter') && params[key].present?
        filter_name = key.delete_suffix('_filter')
        @filter[filter_name] = value
      end
    end
    @game = Game.find(params[:game_id])
    @pagy, @groups = pagy(Group.where(@filter))

    if params['search'].present?
      @groups = @groups.where('description ILIKE ?', "%#{params['search']}%")
      @search = params['search']
    end
  end

  # GET /groups/1 or /groups/1.json
  def show
    @game = Game.find(params[:game_id])
  end

  # GET /groups/new
  def new
    @game = Game.find(params[:game_id])
    @group = Group.new
  end

  # GET /groups/1/edit
  def edit
    @game = @group.game
  end

  # POST /groups or /groups.json
  def create
    authenticate_user!

    @game = Game.find(params[:game_id])
    @group = @game.groups.create(group_params)
    @group.group_memberships.create(user: current_user, owner: true)

    respond_to do |format|
      if @group.save
        format.html { redirect_to game_group_url(@game, @group), notice: "Group was successfully created." }
        format.json { render :show, status: :created, location: @group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  def join
    authenticate_user!

    game = Game.find(params[:game_id])
    group = Group.find(params[:id])

    return redirect_to game_group_url(game, group), notice: 'You are already a member of this group!' if group.members.exists?(current_user.id)
    return redirect_to game_group_url(game, group), notice: 'This group is already full' if group.members.size > group.max_member_count

    group.members << current_user

    redirect_to game_group_url(game, group), notice: "You are now a member of #{group.group_name}"
  end

  # PATCH/PUT /groups/1 or /groups/1.json
  def update
    @game = @group.game
    respond_to do |format|
      if group_params[:join]
        if @group.current_member_count >= @group.max_member_count
          format.html { redirect_to game_group_url(@game, @group), notice: "You cannot join a full group!" }
        elsif @group.update(current_member_count: @group.current_member_count + 1)
          format.html { redirect_to game_group_url(@game, @group), notice: "Join success" }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @group.errors, status: :unprocessable_entity }
        end
      elsif @group.update(group_params)
        format.html { redirect_to game_group_url(@game, @group), notice: "Group was successfully updated." }
        format.json { render :show, status: :ok, location: @group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1 or /groups/1.json
  def destroy
    # @group.destroy
    @game = Game.find(@group.game_id)
    @game.groups.destroy(@group)
    respond_to do |format|
      format.html { redirect_to game_groups_url(@game), notice: "Group was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def group_params
      params.require(:group).permit(:group_name, :activity, :description, :leader_name, :max_member_count, :game_id, :join)
    end
end
