# Copyright © Emilio González Montaña
# Licence: Attribution & no derivatives
#   * Attribution to the plugin web page URL should be done if you want to use it.
#     https://redmine.ociotec.com/projects/redmine-plugin-scrum
#   * No derivatives of this plugin (or partial) are allowed.
# Take a look to licence.txt file at plugin root folder for further details.

require_dependency 'calendars_controller'

module Scrum
  module CalendarsControllerPatch
    def self.included(base)
      base.class_eval do

        around_action :add_sprints, :only => [:show]

        def add_sprints
          yield
          sprints = []
          query_sprints(sprints, @query, @calendar, true)
          query_sprints(sprints, @query, @calendar, false)
          
          tpl_path = File.join(File.dirname(__FILE__), '..', '..', 'app', 'views', 'scrum_hooks', 'calendars')
          lookup_context = ActionView::LookupContext.new(tpl_path)
          context = ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
          renderer = ActionView::PartialRenderer.new(lookup_context, {locals: {:sprints => sprints}})
          @a = renderer.render('sprints', context, nil)# 'scrum_hooks/calendars/sprints'})
          response.body += @a.body
        end

      private

        def query_sprints(sprints, query, calendar, start)
          date_field = start ? 'sprint_start_date' : 'sprint_end_date'
          query.sprints.where(date_field => calendar.startdt..calendar.enddt,
                              is_product_backlog: false).each do |sprint|
            sprints << {:name => sprint.name,
                        :url => url_for(:controller => :sprints,
                                        :action => :show,
                                        :id => sprint.id,
                                        :only_path => true),
                        :day => sprint.send(date_field).day,
                        :week => sprint.send(date_field).cweek,
                        :start => start}
          end
        end

      end
    end
  end
end
