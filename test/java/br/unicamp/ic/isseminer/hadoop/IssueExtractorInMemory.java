package br.unicamp.ic.isseminer.hadoop;

import java.util.ArrayList;

import br.unicamp.ic.miner.domain.core.IssueNodeBuilder;
import br.unicamp.ic.miner.domain.core.IssueImporter;
import br.unicamp.ic.miner.domain.core.IssueNode;

public class IssueExtractorInMemory extends IssueImporter {

	@Override
	public IssueNode extractIssue(String url) {
		
		
		StringBuilder description = new StringBuilder();
		description.append(" Unit test fails on Windows: org.apache.hadoop.dfs.TestLocalDFS.testWorkingDirectory");
		description.append(" Error from failure:");
		description.append(" junit.framework.AssertionFailedError: expected:<hdfs://localhost:1925/user/SYSTEM> but was:<hdfs://localhost:1925/user/hadoopqa>");
		description.append(" at org.apache.hadoop.dfs.TestLocalDFS.testWorkingDirectory(TestLocalDFS.java:81)");
		description.append("Changes:");
		description.append("<a href=https://issues.apache.org/jira/browse/HADOOP-2931>HADOOP-2931</a> IOException thrown by DFSOutputStream had wrong stack trace in some cases.");
		description.append("<a href=https://issues.apache.org/jira/browse/HADOOP-2758>HADOOP-2931</a> Reduce buffer copies in DataNode when data is read from HDFS, without negatively affecting read throughput.");
		
		return new IssueBuilder("HADOOP-2973", description.toString()).withType("BUG").build();
	}

	@Override
	public void extractIssuesFrom(int start, int end) {
		issues = new ArrayList<IssueNode>();
	}

	
	@Override
	public void extractForest() {
		// TODO Auto-generated method stub
	}

	@Override
	public boolean urlPatternMatch(String url) {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public void extractTopologicalData() {
		// TODO Auto-generated method stub
		
	}

}
