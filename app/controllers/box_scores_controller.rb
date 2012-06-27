class BoxScoresController < ApplicationController
  # GET /box_scores
  # GET /box_scores.json
  def index
    @box_scores = BoxScore.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @box_scores }
    end
  end

  # GET /box_scores/1
  # GET /box_scores/1.json
  def show
    @box_score = BoxScore.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @box_score }
    end
  end

  # GET /box_scores/new
  # GET /box_scores/new.json
  def new
    @box_score = BoxScore.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @box_score }
    end
  end

  # GET /box_scores/1/edit
  def edit
    @box_score = BoxScore.find(params[:id])
  end

  # POST /box_scores
  # POST /box_scores.json
  def create
    @box_score = BoxScore.new(params[:box_score])

    respond_to do |format|
      if @box_score.save
        format.html { redirect_to @box_score, notice: 'Box score was successfully created.' }
        format.json { render json: @box_score, status: :created, location: @box_score }
      else
        format.html { render action: "new" }
        format.json { render json: @box_score.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /box_scores/1
  # PUT /box_scores/1.json
  def update
    @box_score = BoxScore.find(params[:id])

    respond_to do |format|
      if @box_score.update_attributes(params[:box_score])
        format.html { redirect_to @box_score, notice: 'Box score was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @box_score.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /box_scores/1
  # DELETE /box_scores/1.json
  def destroy
    @box_score = BoxScore.find(params[:id])
    @box_score.destroy

    respond_to do |format|
      format.html { redirect_to box_scores_url }
      format.json { head :no_content }
    end
  end
end
