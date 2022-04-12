Dir.glob(Dir.pwd + '/lib/**/*.rb').each do |file_path|
  require file_path
end
