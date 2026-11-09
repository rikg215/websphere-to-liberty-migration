<%@ page import="javax.naming.*, javax.sql.*, java.sql.*" %>
<html><body>
<h1>Lab App</h1>
<%
  DataSource ds = (DataSource) new InitialContext().lookup("jdbc/labapp");
  Connection c = ds.getConnection();
  Statement s = c.createStatement();
  ResultSet rs = s.executeQuery("SELECT * FROM websphere");
  ResultSetMetaData md = rs.getMetaData();
  int cols = md.getColumnCount();

  out.println("<table border='1'><tr>");
  for (int i = 1; i <= cols; i++) out.println("<th>" + md.getColumnName(i) + "</th>");
  out.println("</tr>");
  while (rs.next()) {
    out.println("<tr>");
    for (int i = 1; i <= cols; i++) out.println("<td>" + rs.getString(i) + "</td>");
    out.println("</tr>");
  }
  out.println("</table>");

  rs.close(); s.close(); c.close();
%>
</body></html>
