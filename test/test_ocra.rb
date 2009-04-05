require "test/unit"
require "ocra"
require "tmpdir"
require "fileutils"

class TestOcra < Test::Unit::TestCase

  def initialize(*args)
    super(*args)
    @testnum = 0
    @ocra = File.expand_path(File.join(File.dirname(__FILE__), '../bin/ocra.rb'))
  end

  def ocra
    @ocra
  end
  
  def setup
    @testnum += 1
    @tempdirname = ".ocratest-#{$$}-#{@testnum}"
    Dir.mkdir @tempdirname
    Dir.chdir @tempdirname
  end

  def teardown
    Dir.chdir '..'
    FileUtils.rm_rf @tempdirname
  end
  
  def test_helloworld
    File.open("helloworld.rb", "w") do |f|
      f << "hello_world = \"Hello, World!\"\n"
    end
    assert system("ruby", ocra, "--quiet", "helloworld.rb")
    assert File.exist?("helloworld.exe")
    assert system("helloworld.exe")
  end

  def test_writefile
    File.open("writefile.rb", "w") do |f|
      f << "File.open(\"output.txt\", \"w\") do |f| f.write \"output\"; end"
    end
    assert system("ruby", ocra, "--quiet", "writefile.rb")
    assert File.exist?("writefile.exe")
    assert system("writefile.exe")
    assert File.exist?("output.txt")
    assert "output", File.read("output.txt")
  end

  def test_exitstatus
    File.open("exitstatus.rb", "w") do |f|
      f << "exit 167 if __FILE__ == $0"
    end
    assert system("ruby", ocra, "--quiet", "exitstatus.rb")
    system("exitstatus.exe")
    assert_equal 167, $?.exitstatus
  end

  def test_arguments
    File.open("arguments.rb", "w") do |f|
      f << "if $0 == __FILE__\n"
      f << "exit 1 if ARGV.size != 3\n"
      f << "exit 2 if ARGV[0] != \"foo\"\n"
      f << "exit 3 if ARGV[1] != \"bar baz\"\n"
      f << "exit 4 if ARGV[2] != \"\\\"smile\\\"\"\n"
      f << "exit(5)\n"
      f << "end"
    end
    assert system("ruby", ocra, "--quiet", "arguments.rb")
    assert File.exist?("arguments.exe")
    system(File.expand_path("arguments.exe"), "foo", "bar baz", "\"smile\"")
    assert_equal 5, $?.exitstatus
  end

  def test_stdout_redir
    File.open("stdoutredir.rb", "w") do |f|
      f << "if $0 == __FILE__\n"
      f << "puts \"Hello, World!\"\n"
      f << "end\n"
    end
    assert system("ruby", ocra, "--quiet", "stdoutredir.rb")
    assert File.exist?("stdoutredir.exe")
    system("stdoutredir.exe > output.txt")
    assert File.exist?("output.txt")
    assert_equal "Hello, World!\n", File.read("output.txt")
  end

  def test_stdin_redir
    File.open("input.txt", "w") do |f|
      f << "Hello, World!\n"
    end
    File.open("stdinredir.rb", "w") do |f|
      f << "if $0 == __FILE__\n"
      f << "  exit 104 if gets == \"Hello, World!\\n\""
      f << "end\n"
    end
    assert system("ruby", ocra, "--quiet", "stdinredir.rb")
    assert File.exist?("stdinredir.exe")
    system("stdinredir.exe < input.txt")
    assert 104, $?.exitstatus
  end

  def test_gdbmdll
    File.open("gdbmdll.rb", "w") do |f|
      f << "require 'gdbm'\n"
      f << "exit 104 if $0 == __FILE__ and defined?(GDBM)\n"
    end
    assert system("ruby", ocra, "--quiet", "--dll", "gdbm.dll", "gdbmdll.rb")
    path = ENV['PATH']
    ENV['PATH'] = "."
    begin
      system("gdbmdll.exe")
    ensure
      ENV['PATH'] = path
    end
    assert_equal 104, $?.exitstatus
  end
  
end
