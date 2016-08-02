require 'nokogiri'
# require 'watir'
# require 'optparse'
require 'rbconfig'
require 'pp'
require 'pry'
require 'erb'
require 'active_support/all'
require 'ostruct'
require 'fileutils'
require 'yaml'
require 'curb'
require 'open-uri'
require 'json'

OVERVIEW_API = "http://course.ucsc-extension.edu/modules/shop/offeringOverview.action"
OFFERING_API = "http://course.ucsc-extension.edu/modules/shop/searchOfferings.action"
DETAIL_API  = "http://course.ucsc-extension.edu/modules/shop/defaultSections.action"
FULL_SCHEDULE_API = "http://course.ucsc-extension.edu/modules/shop/sectionSchedule.action"

COURSES = {
  "computer_programming": 80,
  "db_and_data_analytics": 83,
  "internet_programming_and_development": 95
}
# curl ''  --data '&CatalogID=80&startPosition=0&pageSize=100' --compressed
module UcscExtCourses
  module Exec

    class Schedule
      def initialize(args)
        @courses = []
        run
      end

      def run
        COURSES.each do |cate_name, cate_id|
          @cate_name = cate_name
          http = Curl.get(OFFERING_API, {:CatalogID => cate_id, :startPosition => 0})
          doc = Nokogiri::HTML.parse(http.body_str)
          offering_and_section_ids = get_offering_and_section_ids(doc)
          fetch_courses(offering_and_section_ids)
        end
        export("courses")
      end

      def get_offering_and_section_ids(doc)
        doc.css("section").inject([]) do |h, item|
          h << {
            "offeringid" => item.css("offeringid").text.to_i,
            "sectionid" => item.css("sectionid").text.to_i,
          }
          h
        end
      end

      def fetch_courses(offering_and_section_ids)
        offering_and_section_ids.each do |item|
          @offeringid = item['offeringid']
          @sectionid = item['sectionid']
          @course = {}
          @course["cate_name"] = @cate_name
          _get_overview
          _get_deatil
          _get_schedules
          pp(@course)
          @courses << @course
        end
      end

      def _get_overview
        req = Curl.get(OVERVIEW_API, {:OfferingID=> @offeringid, :SectionID=> @sectionid })
        doc = Nokogiri::XML.parse(req.body_str)
        @course = @course.merge({
                  course_name: doc.search("Name").text.gsub("Prerequisite(s):",""),
                  course_id: doc.search("CourseID").text,
                  # description: doc.search("Description").text,
                })
      end

      def _get_schedules
        req = Curl.get(FULL_SCHEDULE_API, {:SectionID=> @sectionid })
        doc = Nokogiri::XML.parse(req.body_str)
        schedules = doc.search("//Meeting").collect do |meeting|
          {
            name: meeting.search("Name").text,
            start_date: meeting.search("StartDate").text,
            end_date: meeting.search("EndDate").text,
          }
        end
        @course = @course.merge({
          meeting_days_count: schedules.count,
          meeting_days_events: schedules,
        })
      end

      def _get_deatil
        req = Curl.get(DETAIL_API, {:OfferingID=> @offeringid, :SectionID=> @sectionid })
        doc = Nokogiri::XML.parse(req.body_str)
        begin
          date_items = {
            start_date: doc.search("StartDate").text.to_datetime.to_datetime,
            end_date: doc.search("EndDate").text.to_datetime.to_datetime,
            termination_date: doc.search("TerminationDate").text.to_datetime.to_datetime,
            final_enrollment_date: doc.search("FinalEnrollmentDate").text.to_datetime.to_datetime,
          }
        rescue Exception => e
          date_items = {}
        end
        detail_course = {
          course_number: doc.search("data/Section/SectionNumber").text,
          credit_hours: doc.search("CreditHours").text.to_f,
          tuition_cost: doc.search("Cost").text.to_f,
          site_name: doc.search("SiteName").text,
          section_id: doc.search("SeatGroup//SectionID").text,
        }.merge(date_items)

        @course = @course.merge(detail_course)

      end

      def export(name)
        File.open("#{name}.json","w") do |f|
          f.write(JSON.pretty_generate(@courses))
        end
      end

    end
  end
end
