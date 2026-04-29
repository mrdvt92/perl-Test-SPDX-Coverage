use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Test::SPDX::Coverage',
    VERSION_FROM      => 'lib/Test/SPDX/Coverage.pm',
    PREREQ_PM         => {
                          'License::SPDX' => 0,
                          'Test::Builder' => 0,
                          'Test::More'    => 0,
                         },
    ABSTRACT_FROM     => 'lib/Test/SPDX/Coverage.pm',
    AUTHOR            => 'Michael R. Davis',
    LICENSE           => 'mit',
);
