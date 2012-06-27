class BoxScoreEntriesController < ApplicationController
  # GET /box_score_entries
  # GET /box_score_entries.json
  def index
    @box_score_entries = BoxScoreEntry.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @box_score_entries }
    end
  end

  # GET /box_score_entries/1
  # GET /box_score_entries/1.json
  def show
    @box_score_entry = BoxScoreEntry.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @box_score_entry }
    end
  end

  # GET /box_score_entries/new
  # GET /box_score_entries/new.json
  def new
    @box_score_entry = BoxScoreEntry.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @box_score_entry }
    end
  end

  # GET /box_score_entries/1/edit
  def edit
    @box_score_entry = BoxScoreEntry.find(params[:id])
  end

  # POST /box_score_entries
  # POST /box_score_entries.json
  def create
    @box_score_entry = BoxScoreEntry.new(params[:box_score_entry])

    respond_to do |format|
      if @box_score_entry.save
        format.html { redirect_to @box_score_entry, notice: 'Box score entry was successfully created.' }
        format.json { render json: @box_score_entry, status: :created, location: @box_score_entry }
      else
        format.html { render action: "new" }
        format.json { render json: @box_score_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /box_score_entries/1
  # PUT /box_score_entries/1.json
  def update
    @box_score_entry = BoxScoreEntry.find(params[:id])

    respond_to do |format|
      if @box_score_entry.update_attributes(params[:box_score_entry])
        format.html { redirect_to @box_score_entry, notice: 'Box score entry was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @box_score_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /box_score_entries/1
  # DELETE /box_score_entries/1.json
  def destroy
    @box_score_entry = BoxScoreEntry.find(params[:id])
    @box_score_entry.destroy

    respond_to do |format|
      format.html { redirect_to box_score_entries_url }
      format.json { head :no_content }
    end
  end
end
