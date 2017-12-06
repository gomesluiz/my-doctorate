package br.unicamp.ic.isseminer.hadoop.tests;

import org.junit.runner.RunWith;
import org.junit.runners.Suite;
import org.junit.runners.Suite.SuiteClasses;

@RunWith(Suite.class)
@SuiteClasses({ IssueExtractorTest.class, TraversalIssueTreeTester.class })
public class AllTests {

}
