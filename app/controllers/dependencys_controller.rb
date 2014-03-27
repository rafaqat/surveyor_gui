class DependencysController < ApplicationController

  def new
    prep_variables
    @title = "Add Logic for "+@this_question
    @question.build_dependency(:rule=>'A').dependency_conditions.build(:rule_key=>'A')
  end

  def edit
    prep_variables
    @title = "Edit Logic for Question "+@this_question
  end

  def create
    @question = Question.new(params[:question])
    if @question.save
      redirect_to :back
    else
      render :action => 'new', :layout=>'colorbox'
    end
  end

  def update
    @title = "Update Question"
    @question = Question.includes(:answers).find(params[:id])
    if @question.update_attributes(params[:question])
      @question.dependency.destroy if @question.dependency.dependency_conditions.blank?
      render :blank, :layout=>'colorbox'
    else
      prep_variables
      render :action => 'edit', :layout=>'colorbox'
    end
  end

  def destroy
    question = Question.find(params[:id])
    question.dependency.destroy
    render :nothing=>true
  end

  def get_answers
    options=""
    question_id =  params[:question_id]
    question = Question.find(question_id)
    if question && question.answers
      question.answers.each_with_index do |a, index|
        options += '<option ' +
         (index == 0 ? 'selected="selected" ' : '') +
         'value="' + a.id.to_s + '"' +
         '>'+a.text.to_s+"</option>"
      end
    end
    render :inline=>options
  end

  def get_question_type
    question_id =  params[:question_id]
    question = Question.find(question_id)
    response=question.pick
    if question.pick == 'none'
      response += ','+question.answers.first.response_class.to_s
    else
      response += ',default'
    end
    response += ','+question.display_type
    render :inline=>response
  end

private

  def prep_variables
    @question = Question.includes(:dependency).find(params[:id]) unless @question
    @question_ids = get_question_ids(@question)
    @question_ids.delete(nil)
    @operators = get_operators
    @this_question = @question_ids.select{|q| q[1]==@question.id}[0][0]
    @question_ids.delete_at(@question_ids.index{|q| q[1]==@question.id})
    answer = Question.find(@question_ids.last[1]).answers
    @answers = answer.map{|a| [a.text, a.id]}
  end

  def get_question_ids(question)
    survey_id = question.survey_section.survey.id

    qarray = []
    questions = Question.unscoped.joins(:survey_section).where('survey_id = ? and display_type!=?', survey_id,"label").order('survey_sections.display_order','survey_sections.id','questions.display_order')
    questions.each_with_index do |q, index|
      #dependencies can only be applied multiple choice (pick != none) and number questions (float)
      if q.id == question.id || q.pick != 'none' || q.answers.first.response_class=='float'
        qarray[index] = [(index+1).to_s+') '+q.text, q.id]
      end
    end
    return qarray
  end


  def get_operators
    return [
      ['equal to (=)','=='],
      ['not equal to','!='],
      ['less than (<)','<'],
      ['less than or equal to (<=)','<='],
      ['greater than or equal to (>=)','>='],
      ['greater than','>']
    ]
  end
end
