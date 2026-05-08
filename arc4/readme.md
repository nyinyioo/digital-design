
## ARC4 Cipher
Implements ARC 4 algorithm to decrypt ciphertext.

<table style="font-size: 0.9em">
  <tr>
    <th>Module</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>init</code></td>
    <td>Initializes a 256-byte array with <code>s[i] = i</code></td>
  </tr>
  <tr>
    <td><code>ksa</code></td>
    <td>Key Scheduling Algorithm - scrambles the init array using a 24-bit key</td>
  </tr>
  <tr>
    <td><code>prga</code></td>
    <td>Pseudo-Random Generation Algorithm - XORs keystream against ciphertext to produce plaintext</td>
  </tr>
  <tr>
    <td><code>arc4</code></td>
    <td>Full ARC4 pipeline - sequences <code>init -&gt; ksa -&gt; prga</code> using a ready/enable handshake</td>
  </tr>
  <tr>
    <td><code>crack</code></td>
    <td>Brute-forces the 24-bit key space <code>[0x000000, 0xFFFFFF]</code><br>runs the full ARC4 pipeline for each candidate key and checks if the result is valid ASCII</td>
  </tr>
  <tr>
    <td><code>doublecrack</code></td>
    <td>Runs two <code>crack</code> cores in parallel, splits the key space into even and odd keys<br>reduces search time by ~2×</td>
  </tr>
</table>


### Demos
<p>
  <img src="docs/demo_imgs/key.jpg" width="28.25%"/>
  <img src="docs/demo_imgs/crack.png" width="40%"/>
</p>

### Note
Completed in a team of two. Shared with permissions.