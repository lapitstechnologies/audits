# Smart Contract Security Audits 

This repository contains the security audit reports conducted by Lapits for its clients. The smart contracts have been reviewed for the following weaknesses with the help of automated software, and manual review. 
Report styles are subject to change or update overtime
## Note
These audits do not gaurantee complete safety of code. Lapits is not liable for damages or harm caused to any individual/organization through the code present in this repository.


## Software Used

<ul>
  <li><a href="https://github.com/crytic/slither">Slither</a></li>
  <li><a href="https://github.com/ConsenSys/mythril">Mythril</a></li>
  <li><a href="https://github.com/crytic/echidna">Echidna</a></li>
</ul>

## Vulnerability Indicators

To assess the severity of exploits, one can refer to this table
 <table>
  <tr>
  <th>Indicator</th>
  <th>Severity</th>
  <th>Description</th>
  </tr>
  <tr>
    <td><img src="https://github.com/lapitstechnologies/audits/blob/main/Images/image13.png" alt="Critical"></td>
    <td>Critical</td>
    <td>Critical vulnerabilities lead to major exploits, asset loss or data manipulations</td>
  </tr>
  <tr>
    <td><img src="https://github.com/lapitstechnologies/audits/blob/main/Images/image3.png" alt="Major"></td>
    <td>Major</td>
    <td>Major vulnerabilities have a significant impact on smart contract execution, e.g., public access to crucial functions</td>
  </tr>
  <tr>
    <td><img src="https://github.com/lapitstechnologies/audits/blob/main/Images/image9.png" alt="Medium"></td>
    <td>Medium</td>
    <td>Medium-level vulnerabilities are important to fix. However, they cannot lead to asset loss or data manipulations</td>
  </tr>
  <tr>
    <td><img src="https://github.com/lapitstechnologies/audits/blob/main/Images/image8.png" alt="Minor"></td>
    <td>Minor</td>
    <td>Minor vulnerabilities are related to outdated or unused code snippets that cannot have a significant impact on execution</td>
  </tr>
  <tr>
    <td><img src="https://github.com/lapitstechnologies/audits/blob/main/Images/image4.png" alt="Informational"></td>
    <td>Informational</td>
    <td>Informational vulnerabilities do not pose a risk to security. These are merely improvements over the existing code</td>
  </tr>
 </table>





