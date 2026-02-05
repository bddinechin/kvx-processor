#!/usr/bin/ruby
#
# Copyright (C) 2014-2025 Kalray SA.
#
# All rights reserved.

$LOAD_PATH.push('metabuild/lib')
require 'metabuild'
include Metabuild

options = Options.new(
  'open64' => ['open64', 'Path to open64'],
  'lao' => ['lao', 'Path to lao'],
  'binutils' => ['binutils', 'Path to binutils'],
  'gdb' => ['gdb', 'Path to gdb'],
  'gcc' => ['gcc', 'Path to gcc'],
  'mppadl' => ['mppadl', 'Path to mppadl'],
  'mds' => ['mds', 'Path to MDS'],
  'trace' => ['trace', 'Path to trace clone'],
  'oce' => ['trace', 'Path to oce clone'],
  'iss' => ['iss', 'Path to ISS'],
  'iss_core' => ['iss_core', 'Path to ISS Core'],
  'clusterOS' => ['clusterOS', 'Path to ClusterOS'],
  'mppa_bare_runtime' => ['mppa_bare_runtime', 'Path to MPPA bare runtime'],
  'architecture' => ['architecture', 'Path to MDS FE description files'],
  'qemu' => ['qemu', 'Path to QEMU'],
  'qemu_valid' => ['qemu-valid', 'Path to qemu-valid'],
  'llvm' => ['llvm-project', 'Path to LLVM'],
  'kalrayReq' => ['none', 'Path to kalrayReq env containing latex stuff.'],
  'avp' => {
    'type' => 'string',
    'default' => '',
    'help' => 'Enable AVP generation in MDS by passing directory where to install files.'
  },
  'build_type' => ['Debug', 'Choose build type (Debug/Release)'],
  'version' => ['undef', 'Version of the delivered tools.'],
  'artifacts' => {
    'type' => 'string',
    'default' => '',
    'help' => 'Artifacts path given by Jenkins.'
  }
)

arch            = options['target']
march           = options['march']
build_type      = options['build_type']
march_list      = march_list(march)
workspace       = options['workspace']
processor_clone = options['clone']
processor_path  = File.join(workspace, processor_clone)
jobs            = options['jobs']
artifacts       = options['artifacts']
artifacts       = File.expand_path(artifacts) unless artifacts.empty?
toolroot        = options['toolroot']
kalray_req      = options['kalrayReq']
prefix          = options.fetch('prefix', File.expand_path('none', workspace))
local_kalray_internal = File.join(prefix, 'processor', 'kalray_internal')
family_install_prefix = File.join(local_kalray_internal, "#{arch}-family")
kalray_internal = File.join(prefix, 'kalray_internal')
install_prefix  = File.join(prefix, 'processor', 'devimage')
toolroot_kalray_internal = File.join(toolroot, 'kalray_internal')
avp             = !options['avp'].empty? ? '--enable-avp' : '--disable-avp'
pkg_prefix_name = options.fetch('pi-prefix-name', "#{arch}-")

lao_clone          = options['lao']
gdb_clone          = options['gdb']
binutils_clone     = options['binutils']
gcc_clone          = options['gcc']
mppadl_clone       = options['mppadl']
mds_clone          = options['mds']
iss_clone          = options['iss']
trace_clone        = options['trace']
oce_clone          = options['oce']
iss_core_clone     = options['iss_core']
cos_clone          = options['clusterOS']
mbr_clone          = options['mppa_bare_runtime']
architecture_clone = options['architecture']
qemu_clone         = options['qemu']
qemu_valid_clone   = options['qemu_valid']
llvm_clone         = options['llvm']

lao_path          = File.join(workspace, lao_clone)
gdb_path          = File.join(workspace, gdb_clone)
binutils_path     = File.join(workspace, binutils_clone)
gcc_path          = File.join(workspace, gcc_clone)
mppadl_path       = File.join(workspace, mppadl_clone)
gcc_path          = File.join(workspace, gcc_clone)
mds_path          = File.join(workspace, mds_clone)
iss_path          = File.join(workspace, iss_clone)
trace_path        = File.join(workspace, trace_clone)
oce_path          = File.join(workspace, oce_clone)
iss_core_path     = File.join(workspace, iss_core_clone)
cos_path          = File.join(workspace, cos_clone)
mbr_path          = File.join(workspace, mbr_clone)
architecture_path = File.join(workspace, architecture_clone)
qemu_path         = File.join(workspace, qemu_clone)
qemu_valid_path   = File.join(workspace, qemu_valid_clone)
llvm_path         = File.join(workspace, llvm_clone)

raise "Unknown target: #{arch}" unless arch == 'kvx'

repo = Git.new(processor_clone, workspace)

clean          = CleanTarget.new('clean', repo)

# generation from mds
configure      = Target.new('configure', repo)
build          = ParallelTarget.new('build', repo, depends: [configure])
qemu_build     = Target.new('qemu_build', repo, depends: [build])
gen_valid      = Target.new('gen_valid', repo, depends: [build])

# references
refs           = Target.new('refs', repo, depends: [build])
refs_valid     = Target.new('refs_valid', repo, depends: [refs])

# docs
docs_build     = ParallelTarget.new('docs_build', repo, depends: [refs]) #TODO: s/refs/build/
docs_valid     = Target.new('docs_valid', repo, depends: [docs_build])

# main targets
valid          = Target.new('valid', repo, depends: [gen_valid, refs_valid, docs_valid])
install        = Target.new('install', repo, depends: [refs, docs_build]) #TODO: s/refs/build/
package        = PackageTarget.new('package', repo, depends: [install, valid])

# other modules related
refs          = Target.new('refs', repo, depends: [build])
elfids_export = Target.new('elfids_export', repo, depends: [install])
export        = Target.new('export', repo, depends: [install, elfids_export])
rsync         = Target.new('rsync', repo, depends: [refs])

qemu_export   = Target.new('qemu_export', repo, depends: [qemu_build])

# avp
avp_valid      = Target.new('avp_valid', repo)

b = Builder.new('processor', options, [clean, configure, build, install, package, valid])
b.add_target([docs_build, docs_valid])
b.add_target([gen_valid, refs_valid])

b.add_target([refs, elfids_export, export])
b.add_target([qemu_build, qemu_export])
b.add_target([avp_valid])
b.add_target([rsync])

b.default_targets = [package] if b.distrib_info.architecture != 'aarch64'
b.logsession = arch

skip_build = false

family_prefix = File.join(processor_path, "#{arch}-family")
archi_prefix = File.join(architecture_path, "#{arch}-family")
family_build_dir = File.join(family_prefix, "#{arch}_build")
avp_build_dir = options['avp']
cores = []

march_list.each do |gen, versions|
  warn "Core generation: #{gen}, versions: #{versions}"
  versions.split(',').each do |ver|
    # Note: this is formatted as: kvX_vY
    cores.push("#{gen}_#{ver}")
  end
end

vliwcore_prefix = File.join(processor_path, 'VLIWCore')
vliwcore_build = File.join(vliwcore_prefix, 'build')

b.target('clean') do
  b.logtitle = "Report for processor clean, target = #{arch}"

  FileUtils.rm_rf(family_build_dir)
  FileUtils.rm_rf("#{vliwcore_prefix}/build")
end

b.target('docs_build') do
  b.logtitle = "Report for processor build, target = #{arch}"

  cores.each do |core|
    # Build of kvx documents.
    cmd = "cd #{vliwcore_prefix} " \
          ' && make ' \
          "KALRAY_REQ_DIR=#{kalray_req} " \
          "BUILDTYPE=#{build_type} " \
          "DESTDIR=#{vliwcore_build} " \
          "TOOLROOT=#{toolroot} " \
          "ARCH=#{arch} " \
          "CORE=#{core} " \
          'all'
    b.run(cmd: cmd)
  end

  # Build of Changes doc for Coolidge V1/V2
  if cores.include?('kv3-v2') && cores.include?('kv3-v1')
    b.run(cmd: "KALRAY_TOOLCHAIN_DIR=#{File.join(kalray_req, '..', 'accesscore')} " \
               "make -C #{File.join(architecture_path, 'ChangesDoc')} " \
                     "FE_PATH=#{File.join(family_prefix, 'FE', 'YAML', arch)}")
  end
end

b.target('docs_valid') do
  b.logtitle = "Report for processor docs_valid, target = #{arch}"
  cores.each do |core|
    # Build of kvx documents.
    b.valid(cmd: "cd #{vliwcore_prefix} && "\
                 "make ARCH=#{arch} CORE=#{core} KALRAY_REQ_DIR=#{kalray_req} "\
                      "TOOLROOT=#{toolroot} BUILDTYPE=#{build_type} -j #{jobs} valid",
            skip: skip_build)
  end
end

mds_make_env = {
  # AVP config
  'AVP_CACHE' => '1',
  'AVP_FORK' => jobs.to_s,
  # disable QEMU backend by default (we have qemu_build/install targets)
  'MDS_SKIP_BE' => 'QEMU'
}
mds_backends = %w[LAO ISS TEX GBU MPPADL LINUX GDB GCC VHD TDH HW_TEST]

b.target('configure') do
  b.logtitle = "Report for processor configure, target = #{arch}"

  b.create_goto_dir! family_build_dir

  # Create the input FE files
  # Note: we could do that in build. But given it would be impossible to
  # identify the inputs needed to trigger a rebuild. Let's put it here. It is
  # easy enough to manually redo this make when working locally (no reconfigure
  # needed after).
  b.run(cmd: "make -C #{File.join(archi_prefix, 'FE', 'YAML', arch)} " \
                   "CORES='#{cores.join(' ')}' " \
                   "OUTPUTDIR=#{File.join(family_build_dir, 'FE', 'YAML', arch)}",
        skip: skip_build)

  # Build of MDS arch family
  mds = "#{mds_path}/MDS"
  # For now we cannot disable-mdf, some backends require it
  b.run(cmd: "../configure --target=#{arch} " \
                "--enable-mdf " \
                "--with-mds=#{mds} " \
                "--with-arch-path=#{archi_prefix} " \
                "--with-gdb-prefix=#{gdb_path} " \
                "--with-binutils-prefix=#{binutils_path} " \
                "--with-gcc-prefix=#{gcc_path}/gcc/config/kvx/ " \
                "--with-llvm-prefix=#{llvm_path}/ " \
                "--with-mppadl-prefix=#{mppadl_path} " \
                "--with-iss-path=#{iss_path} " \
                "--with-lao-path=#{lao_path} " \
                "--with-avp-prefix=#{avp_build_dir} " \
                "--with-qemu-prefix=#{qemu_path} " \
                "--with-qemu-valid-prefix=#{qemu_valid_path} " \
                "#{avp}",
        msg: "Unable to configure mds family #{arch}",
        skip: skip_build)
end

b.target('build') do
  b.logtitle = "Report for processor build, target = #{arch}"

  # build up to the merged mdd
  b.run(
    name: '1: generate DOC',
    cmd: "make -C #{File.join(family_build_dir, 'DOC')} all",
    env: mds_make_env,
    skip: skip_build
  )
  b.run(
    name: '2: generate FE/YAML',
    cmd: "make -C #{File.join(family_build_dir, 'FE/YAML')} -j1 all",
    env: mds_make_env,
    skip: skip_build
  )
  b.run(
    name: '3: generate MDD/MDE',
    cmd: "make -C #{File.join(family_build_dir, 'MDD/MDE')} -j1 all",
    env: mds_make_env,
    skip: skip_build
  )
  b.run(
    name: '4: generate MDD/MDF',
    cmd: "make -C #{File.join(family_build_dir, 'MDD/MDF')} -j1 all",
    env: mds_make_env,
    skip: skip_build
  )
  mds_backends.each do |be|
    b.run(
      name: "5: generate BE/#{be}",
      cmd: "make -C #{File.join(family_build_dir, 'BE', be)} all",
      env: mds_make_env,
      skip: skip_build
    )
  end
end

b.target('gen_valid') do
  b.logtitle = "Report for processor gen_valid, target = #{arch}"
  b.valid(cmd: "make -C #{family_build_dir} -j1 check",
          env: mds_make_env,
          msg: 'Unable to check DTD',
          skip: skip_build)
end

b.target('valid') do
  b.logtitle = "Report for processor valid, target = #{arch}"
end

b.target('install') do
  b.logtitle = "Report for processor install, target = #{arch}"

  mkdir_p family_install_prefix

  FileUtils.cp_r(File.join(family_prefix, 'FE'), artifacts) unless artifacts.empty?
  b.run("cp -rf #{family_prefix}/BE  #{family_install_prefix}/")
  b.run("cp -rf #{family_prefix}/MDD #{family_install_prefix}/")
  unless skip_build
    # Manual copy to bypass make diff/make refs because the binary change with perl version
    # Use only first one
    #BD3 b.silent("cp -rf #{family_build_dir}/BE/HW_TEST/kvx/kv3_v1/RB_cover_data " \
    #BD3          "#{kalray_internal}/kvx-family/BE/HW_TEST/kvx/kv3_v1/")
    #BD3 b.silent("cp -rf #{family_build_dir}/BE/HW_TEST/kvx/kv3_v2/RB_cover_data " \
    #BD3          "#{kalray_internal}/kvx-family/BE/HW_TEST/kvx/kv3_v2/")
  end
  b.silent("rm -rf #{File.join(family_install_prefix, '*_build')}")
  b.silent("rm -rf #{File.join(family_install_prefix, 'BE', 'AVP', 'BIN', '*.txt')}")
  doc_dir = File.join(local_kalray_internal, 'share', 'doc')
  mkdir_p doc_dir

  architecture_docs = []
  cores.each do |core|
    core = core.sub('_', '-')
    architecture_docs << File.join(vliwcore_build, arch, "#{core}-VLIWCore.pdf")
    architecture_docs << File.join(vliwcore_build, arch, "#{core}-VLIWCoreABI.pdf")
    #BD3 architecture_docs << File.join(vliwcore_build, arch, "#{core}-Optimization.pdf")
    architecture_docs << File.join(vliwcore_build, arch, "#{core}-RefCard.pdf")
  end
  if cores.include?('kv3-v2') && cores.include?('kv3-v1')
    architecture_docs << File.join(architecture_path, 'ChangesDoc', 'doc', 'doc', 'latex',
                                   'coolidge_v1v2_changes.pdf')
  end
  architecture_docs.each do |doc|
    FileUtils.cp(doc, doc_dir)
    FileUtils.cp(doc, artifacts) unless artifacts.empty?
  end

  cd vliwcore_prefix
  cores.each do |core|
    cmd =  'unset KALRAY_TOOLCHAIN_DIR; ' \
           "cd #{vliwcore_prefix} " \
           '&& make ' \
           "-j #{jobs} " \
           "ARCH=#{arch} " \
           "CORE=#{core} " \
           "KALRAY_REQ_DIR=#{kalray_req} " \
           "DESTDIR=#{vliwcore_build} " \
           "DOC_INSTALL_DESTDIR=#{install_prefix}/ " \
           "DOC_INSTALL_AUX_DESTDIR=#{install_prefix}/aux " \
           'install install-aux'
    b.run(cmd: cmd, msg: 'Unable to install')
  end

  # Copy to toolroot kalray_internal directory
  b.rsync(local_kalray_internal, kalray_internal)
  b.rsync(local_kalray_internal, toolroot_kalray_internal)
end

b.target('rsync') do
  b.logtitle = "Report for processor rsync, target = #{arch}"

  # Copy to toolroot kalray_internal directory
  b.rsync(local_kalray_internal, kalray_internal)
  b.rsync(local_kalray_internal, toolroot_kalray_internal)
end

b.target('qemu_build') do
  b.logtitle = "Report for processor qemu_build, target = #{arch}"

  b.run(cmd: "make -C #{family_build_dir}/BE/QEMU all",
        msg: 'Unable to do qemu generation',
        skip: skip_build)
end

b.target('qemu_export') do
  b.logtitle = "Export files into qemu, target = #{arch}"

  b.run(cmd: "make -C #{family_build_dir}/BE/QEMU install",
        msg: 'Unable to install qemu generation',
        skip: skip_build)
  b.run(cmd: "make -C #{family_build_dir}/BE/GBU install_qemu",
        msg: 'Unable to install qemu disas generation',
        skip: skip_build)
end

b.target('elfids_export') do
  b.logtitle = "Export elfids in lots of modules"

  elfids_file = File.join(family_prefix, 'BE', 'GBU', arch, 'include', 'elf',
                          "#{arch}_elfids.h")
  b.silent("cp #{elfids_file} #{trace_path}/dsu/")
  b.silent("cp #{elfids_file} #{iss_core_path}/iss/include/")
  b.silent("cp #{elfids_file} #{oce_path}/JTAGKey/src/")
  b.silent("cp #{elfids_file} #{mppadl_path}/include/priv/")
  #b.silent("cp #{elfids_file} #{qemu_path}/target/kvx/gen")
end

b.target('export') do
  b.logtitle = 'Export files into other modules'
end

b.target('avp_valid') do
  b.logtitle = "Report for processor AVP valid, target = #{arch}"
end

b.target('refs') do
  b.logtitle = "Report for processor refs, target = #{arch}"
  b.run(cmd: "make -C #{family_build_dir} refs",
        env: mds_make_env,
        msg: 'Unable to install refs',
        skip: skip_build)
end

b.target('refs_valid') do
  b.logtitle = "Report for processor refs_valid, target = #{arch}"
  cd family_prefix
  # do 'git diff &&' first so we see the diffs if any
  b.valid(cmd: 'git diff && test `git diff | wc -l` = 0',
          msg: 'FE Reference files not up to date',
          skip: skip_build)
  b.valid(cmd: "make -C #{family_build_dir} -j1 DIFF=diff diff",
          env: mds_make_env,
          msg: 'Reference files not up to date',
          skip: skip_build)
end

b.target('package') do
  b.logtitle = "Report for processor packaging, target = #{arch}, type = #{build_type}"

  family_pi_prefix = File.join(b.pi_prefix, 'kalray_internal', "#{arch}-family")

  cd install_prefix

  # Binutils
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-gbu",
    desc: "#{arch.upcase} Generated files for gbu (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'BE', 'GBU') => \
                 File.join(family_pi_prefix, 'BE', 'GBU') },
    bg: true
  )

  # GCC
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-gcc",
    desc: "#{arch.upcase} Generated files for gcc (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'BE', 'GCC') => \
                 File.join(family_pi_prefix, 'BE', 'GCC') },
    bg: true
  )

  # GDB
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-gdb",
    desc: "#{arch.upcase} Generated files for gdb (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'BE', 'GDB') => \
                 File.join(family_pi_prefix, 'BE', 'GDB') },
    bg: true
  )

  # HW_TEST
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-hwtest",
    desc: "#{arch.upcase} Generated files for hwtest (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'BE', 'HW_TEST') => \
                 File.join(family_pi_prefix, 'BE', 'HW_TEST') },
    bg: true
  )

  # ISS
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-iss",
    desc: "#{arch.upcase} Generated files for iss (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'BE', 'ISS') => \
                 File.join(family_pi_prefix, 'BE', 'ISS') },
    bg: true
  )

  # LAO
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-lao",
    desc: "#{arch.upcase} Generated files for lao (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'BE', 'LAO') => \
                 File.join(family_pi_prefix, 'BE', 'LAO') },
    bg: true
  )

  # LINUX
  # b.create_package_with_files(
  #   name: "#{pkg_prefix_name}internal-processor-linux",
  #   desc: "#{arch.upcase} Generated files for linux (internal) host package",
  #   pkg_files: { File.join(family_install_prefix, 'BE', 'LINUX') => \
  #                File.join(family_pi_prefix, 'BE', 'LINUX') },
  #   bg: true
  # )

  # MPPADL
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-mppadl",
    desc: "#{arch.upcase} Generated files for mppadl (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'BE', 'MPPADL') => \
                 File.join(family_pi_prefix, 'BE', 'MPPADL') },
    bg: true
  )

  # QEMU
#  b.create_package_with_files(
#    name: "#{pkg_prefix_name}internal-processor-qemu",
#    desc: "#{arch.upcase} Generated files for qemu (internal) host package",
#    pkg_files: { File.join(family_install_prefix, 'BE', 'QEMU') => \
#                 File.join(family_pi_prefix, 'BE', 'QEMU') },
#    bg: true
#  )

  # TDH
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-tdh",
    desc: "#{arch.upcase} Generated files for tdh (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'BE', 'TDH') => \
                 File.join(family_pi_prefix, 'BE', 'TDH') },
    bg: true
  )

  # TEX
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-tex",
    desc: "#{arch.upcase} Generated files for tex (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'BE', 'TEX') => \
                 File.join(family_pi_prefix, 'BE', 'TEX') },
    bg: true
  )

  # VHD
  # b.create_package_with_files(
  #   name: "#{pkg_prefix_name}internal-processor-vhd",
  #   desc: "#{arch.upcase} Generated files for vhd (internal) host package",
  #   pkg_files: { File.join(family_install_prefix, 'BE', 'VHD') => \
  #                File.join(family_pi_prefix, 'BE', 'VHD') },
  #   bg: true
  # )

  # MDD
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-mdd",
    desc: "#{arch.upcase} Generated files for mdd (internal) host package",
    pkg_files: { File.join(family_install_prefix, 'MDD') => \
                 File.join(family_pi_prefix, 'MDD') },
    bg: true
  )

  # VLIWCore
  b.create_package_with_files(
    name: "#{pkg_prefix_name}internal-processor-vliwcore",
    desc: "#{arch.upcase} Generated files for vliwcore (internal) host package",
    pkg_files: { File.join(local_kalray_internal, 'share', 'doc') => \
                 File.join(b.pi_prefix, 'kalray_internal', 'share', 'doc') },
    bg: true
  )


  ## AUX files for processor docs
  package_basename = "#{pkg_prefix_name}processor-aux"
  aux_dir = File.join(install_prefix, 'aux')
  tar_package_doc_aux = File.expand_path("#{package_basename}.tar")
  b.run("cd #{aux_dir} && find -name '*.aux' | xargs tar -cvf #{tar_package_doc_aux}")
  package_description = "#{package_basename} : aux files for making references " \
                        "to #{arch} processor documents\n" \
                        'This package provides aux files for other project ' \
                        "to reference #{arch} processor documents."
  pinfo = b.package_info(
    name: package_basename,
    description: package_description,
    prefix: File.join(b.pi_prefix, 'share/doc')
  )
  b.create_package(tar_package_doc_aux, pinfo)
end

b.launch
