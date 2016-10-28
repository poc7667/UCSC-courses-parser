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


# Here are the WEB API involing to fetch course data
OVERVIEW_API = "http://course.ucsc-extension.edu/modules/shop/offeringOverview.action"
OFFERING_API = "http://course.ucsc-extension.edu/modules/shop/searchOfferings.action"
DETAIL_API  = "http://course.ucsc-extension.edu/modules/shop/defaultSections.action"
FULL_SCHEDULE_API = "http://course.ucsc-extension.edu/modules/shop/sectionSchedule.action"

# To add new category, please do insert a new record here
COURSES = [
  {id:"81", certificate_name:"Account Course Catalog"},
  {id:"82", certificate_name:"Accounting CPA Course Catalog"},
  {id:"85", certificate_name:"Administrative and Executive Assistants Course Catalog"},
  {id:"87", certificate_name:"Bioinformatics Course Catalog"},
  {id:"93", certificate_name:"Biotechnology Course Catalog"},
  {id:"89", certificate_name:"Business Administration Course Catalog"},
  {id:"86", certificate_name:"Certified Bookkeeping Course Catalog"},
  {id:"79", certificate_name:"Clinical Trials Course Catalog"},
  {id:"80", certificate_name:"Computer Programming Course Catalog"},
  {id:"97", certificate_name:"Credential Courses Catalog"},
  {id:"83", certificate_name:"Database and Data Analytics Course Catalog"},
  {id:"99", certificate_name:"Early Childhood Education Course Catalog"},
  {id:"113", certificate_name:"Early Childhood Education: Supervision &amp; Administration Course Catalog"},
  {id:"114", certificate_name:"Educational Therapy Course Catalog"},
  {id:"84", certificate_name:"Environmental Health and Safety Management Course Catalog"},
  {id:"88", certificate_name:"Embedded Systems Course Catalog"},
  {id:"91", certificate_name:"Personal Financial Planning Course Catalog"},
  {id:"111", certificate_name:"General Interest Science Course Catalog"},
  {id:"94", certificate_name:"Human Resources Management Course Catalog"},
  {id:"241", certificate_name:"Information Technology Course Catalog"},
  {id:"115", certificate_name:"Instructional Design and Delivery Course Catalog"},
  {id:"95", certificate_name:"Internet Programming and Development Course Catalog"},
  {id:"101", certificate_name:"Legal Studies Course Catalog"},
  {id:"98", certificate_name:"Linux Programming and Administration Course Catalog"},
  {id:"102", certificate_name:"Marketing Course Catalog"},
  {id:"110", certificate_name:"MBA Prerequisite Course Catalog"},
  {id:"104", certificate_name:"MCLE courses"},
  {id:"112", certificate_name:"Medical Devices Course Catalog"},
  {id:"322", certificate_name:"Mobile Application Development Course Catalog (Professional Award)"},
  {id:"344", certificate_name:"Pre-Health Professions"},
  {id:"105", certificate_name:"Project and Program Management Course Catalog"},
  {id:"78", certificate_name:"Regulatory Affairs Course Catalog"},
  {id:"107", certificate_name:"Software Engineering and Quality Course Catalog"},
  {id:"290", certificate_name:"List of special offerings"},
  {id:"108", certificate_name:"Technical Writing Course Catalog"},
  {id:"117", certificate_name:"Teaching English to Speakers of Other Languages Course Catalog"},
  {id:"118", certificate_name:"VLSI Engineering Course Catalog"},
  {id:"119", certificate_name:"Web and Interactive Media Design Course Catalog"},
]

module UcscExtCourses
  module Exec

    class Schedule
      def initialize(args)
        @courses = []
        run
      end

      def run
        COURSES.each do |certificate|
          cate_name  = certificate[:certificate_name]
          cate_id = certificate[:id]
          @cate_name = cate_name
          http = Curl.get(OFFERING_API, {:id => cate_id, :startPosition => 0})
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
          _get_course_detail
          _get_schedules
          pp(@course)
          @courses << @course
        end
      end

      def _get_overview
        req = Curl.get(OVERVIEW_API, {:OfferingID=> @offeringid, :SectionID=> @sectionid })        
        doc = Nokogiri::XML.parse(req.body_str)
        @course = @course.merge({
                  course_name: formalize_course_name(doc),
                  course_id: doc.search("CourseID").text,
                  description: doc.search("Description").text,
                })
      end

      def formalize_course_name(doc)
        doc.search("Name").text
            .gsub(/Prerequisite(s):/i,"")
            .gsub(/Prerequiste(s):/i,"")
            .gsub(/Prerequisite:/i, "")
            .gsub(/Pre-Requisites/i,"")
            .gsub("Prerequisite(s)","")
            .gsub("Prerequiste(s):","")
            .gsub(/Pre-Requisites/i,"")
            .gsub(/Pre-Requisite/i,"")
            .gsub(/Prerequisites/i,"")
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

      def _get_course_detail
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
          offering_code: @offeringid,
          section_description: CGI::unescapeHTML(doc.search("//Description").text),
          instructor_name: doc.search("Instructors/Instructor/InstructorName").text
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
