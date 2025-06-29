// deploy.ts
import 'https://deno.land/std@0.224.0/dotenv/load.ts';

const [chain] = Deno.args;

const API = Deno.env.get(`${chain.toUpperCase()}_API`);
const KEY = Deno.env.get('KEY');

if (!API || !KEY) {
	console.error('Faltan las variables API o KEY');
	Deno.exit(1);
}

const compile_ChainlinkAccount = new Deno.Command('forge', {
	args: [
		'create',
		'--rpc-url',
		API,
		'--private-key',
		KEY,
    	"--via-ir",
		'--optimizer-runs',
		'42069',
		'./src/ChainlinkPoweredSmartAccount.sol:ChainlinkPoweredSmartAccount',
	],
	stdout: 'inherit',
	stderr: 'inherit',
});

const { code } = await compile_ChainlinkAccount.output();

Deno.exit(code);
