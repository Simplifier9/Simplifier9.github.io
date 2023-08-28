const apiurl = 'https://official-joke-api.appspot.com/random_joke';
const setup = document.getElementById('setup');
const punchline = document.getElementById('punchline');
const newjoke = document.getElementById('new-joke');

async function fetchjoke(){
    try{
        const response = await fetch(apiurl);
        const data = await response.json();
        setup.textContent = data.setup;
        punchline.textContent = data.punchline;
    }
    catch(error)
    {
        console.error('error fetching the joke',error);
        setup.textContent = 'error fetching the joke ' + error.message;
    }
}
fetchjoke();
newjoke.addEventListener('click',fetchjoke);