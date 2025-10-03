class GraphsController < ApplicationController

  def index
    years = Grapher.years
    months_keys, months_data = Grapher.months
    @years_chart = chart( 'Reports of hate crime hoaxes by year', years.keys, years.values )
    @months_chart = chart( 'Recent months with more than two hate crime hoax reports', months_keys, months_data, 'green' )
  end

 private

  def chart( title, categories, data, color=nil )
    LazyHighCharts::HighChart.new('graph') do |f|
      f.colors( [ color ] ) unless color.nil?
      f.title(text: title)
      f.xAxis(categories: categories)
      f.series(name: "No. of reports", yAxis: 1, data: data)

      f.yAxis [
        {title: {text: "", margin: 70} },
        {title: {text: ""}, opposite: true}
      ]

      f.legend(align: 'right', verticalAlign: 'top', y: 75, x: -50, layout: 'vertical')
      f.chart({
        defaultSeriesType: "column",
        backgroundColor: 'transparent',
        plotBackgroundColor: 'transparent'
      })
    end
  end

end
