use clap::{arg, value_parser, Command};

use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyModifiers},
    execute,
    terminal::{
        disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
    },
};
use serialport::{DataBits, FlowControl, Parity, SerialPort, StopBits};
use std::{error::Error, io::{self, BufRead, BufReader, BufWriter, Write}, time::Duration};
use ratatui::{
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Direction, Layout},
    style::Style,
    text::{Line, Span},
    widgets::{Block, Borders, List, ListDirection, ListItem, Padding, Paragraph},
    Frame, Terminal,
};
use tui_input::backend::crossterm::EventHandler;
use tui_input::Input;

fn cli() -> Command {
    Command::new("")
        .subcommand_required(true)
        .arg_required_else_help(true)
        .subcommand(
            Command::new("list")
                .about("Lists available COM Ports")
                .arg_required_else_help(false),
        )
        .subcommand(
            Command::new("connect")
                .about("Connects a Playdate to the Server")
                .arg(arg!(<PORT> "The device port to connect"))
                .arg_required_else_help(true),
        )
        .subcommand(
            Command::new("disconnect")
                .about("Disconnects a Playdate to the Server")
                .arg(arg!(<SLOT> "The device slot to disconnect").value_parser(value_parser!(i32)))
                .arg_required_else_help(true),
        )
}

fn execute_command(app: &mut App) {
    let mut words = shellwords::split(app.input.value()).unwrap();
    let commandname = &["".to_string()];

    words.splice(0..0, commandname.iter().cloned());
    
    let matches_container = cli().try_get_matches_from(words);

    if matches_container.is_err() {
        app.messages.push(matches_container.unwrap_err().render().to_string());

        return;
    }

    let matches = matches_container.unwrap();

    match matches.subcommand() {
        Some(("list", _sub_matches)) => {
            let ports = serialport::available_ports();

            if ports.is_ok() {
                app.messages.push("All Devices:\n".to_string());

                for p in ports.unwrap() {
                    app.messages.push(format!("    {}\n", p.port_name));
                }
            } else {
                app.messages.push("No devices found\n".to_string());
            }
        }
        Some(("connect", sub_matches)) => {
            let port_name = sub_matches.get_one::<String>("PORT").expect("required");

            app.messages.push(format!("Connecting to {}...", port_name));

            let port = serialport::new(port_name, 115200)
                .timeout(Duration::from_millis(100))
                .data_bits(DataBits::Eight)
                .parity(Parity::None)
                .flow_control(FlowControl::None)
                .stop_bits(StopBits::One)
                .open();

            match port {
                Ok(opened_port) => {
                    // let _ = opened_port.write(b"echo off\r\nserialread\r\n").expect("write failed");
                    // let _ = opened_port.flush().expect("flush failed");
    
                    let mut playdate_id: String = "".to_string(); 

                    let test = Box::into_raw(opened_port);
                    let mut test2: *mut dyn SerialPort = unsafe { std::mem::MaybeUninit::zeroed().assume_init() };
                    test2 = test; // holy shit this is jank
    
                    let mut reader = BufReader::new(unsafe{ Box::from_raw(test)});
                    let mut writer = BufWriter::new(unsafe{ Box::from_raw(test2)});

                    let _ = writer.write(b"echo off\r\nserialread\r\n").expect("write failed");
                    let _ = writer.flush().expect("flush failed");

                    loop {
                        let _ = reader.read_line(&mut playdate_id);

                        if playdate_id.starts_with("PDU") {
                            break;
                        }

                        playdate_id = "".to_string(); 
                    }

                    // playdate_id = "".to_string(); 
                    // let _ = reader.read_line(&mut playdate_id);
    
                    app.messages.push(format!("Connected {} as device #{}!", port_name, app.devices.len() + 1));
    
                    app.devices.push((playdate_id.get(0..(playdate_id.len() - 1)).unwrap().to_string(), reader, writer));
                }
                Err(_) => {
                    app.messages.push(format!("Failed to connect to {}.", port_name));
                }
            }
        }
        Some(("disconnect", sub_matches)) => {
            let device_number = *sub_matches.get_one::<i32>("SLOT").expect("required");

            app.messages.push(format!("Disconnecting device #{}...", device_number));

            if device_number > app.devices.len() as i32 || device_number < 1 {
                app.messages.push(format!("No device in slot #{}.", device_number));
            } else {
                let tuple = app.devices.remove((device_number - 1) as usize);
                
                std::mem::drop(tuple.0);
                std::mem::drop(tuple.1);

                app.messages.push(format!("Disconnected device #{}.", device_number));
            }
        }
        _ => {},
    }
}

struct App {
    input: Input,
    messages: Vec<String>,
    bus_messages: Vec<String>,
    devices: Vec<(String, BufReader<Box<dyn SerialPort>>, BufWriter<Box<dyn SerialPort>>)>
}

impl Default for App {
    fn default() -> App {
        App {
            input: Input::default(),
            messages: Vec::new(),
            bus_messages: Vec::new(),
            devices: Vec::new()
        }
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    // setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // create app and run it
    let app = App::default();
    let res = run_app(&mut terminal, app);

    // restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("{:?}", err)
    }

    Ok(())
}

fn run_app<B: Backend>(terminal: &mut Terminal<B>, mut app: App) -> io::Result<()> {
    loop {
        for i in 0..(app.devices.len()) {
            let mut playdate_message: String = "".to_string(); 
        
            match app.devices[i].1.read_line(&mut playdate_message) {
                Ok(_) => {
                    if playdate_message.starts_with("msg") {
                        app.bus_messages.push(format!("{} : {}", app.devices[i].0, playdate_message));
                    
                        for j in 0..(app.devices.len()) {
                            if app.devices[i].0 != app.devices[j].0 {
                                let _ = app.devices[j].2.write(playdate_message.as_bytes());
                                let _ = app.devices[j].2.flush();
                            }
                        }
                    }
                },
                Err(_) => {}
            }
        }

        terminal.draw(|f| ui(f, &mut app))?;

        match event::poll(Duration::from_millis(10)) {
            Ok(ready) => {
                if ready {
                    if let Event::Key(key) = event::read()? {
                        if key.kind == event::KeyEventKind::Press {
                            if key.code == KeyCode::Char('c') && key.modifiers.intersects(KeyModifiers::CONTROL) {
                                return Ok(());
                            }
                        
                            match key.code {
                                KeyCode::Enter => {
                                    if !app.input.value().is_empty() {
                                        app.messages.push(format!("> {}", app.input.value()));
                                    
                                        execute_command(&mut app);
                                    
                                        app.input.reset();
                                    }
                                }
                                _ => {
                                    app.input.handle_event(&Event::Key(key));
                                }
                            }
                        }
                    }
                }
            }
            Err(_) => {}
        }
    }
}

fn ui(frame: &mut Frame, app: &mut App) {
    let main_layout = Layout::new(
        Direction::Vertical,
        [
            Constraint::Length(1),
            Constraint::Min(0),
            Constraint::Length(1),
        ],
    ).split(frame.size());

    // Title and Footer

    frame.render_widget(
        Block::new().borders(Borders::TOP).padding(Padding::horizontal(1)).title(" Playdate Tank Commander Relay Server "),
        main_layout[0],
    );
    frame.render_widget(
        Block::new().borders(Borders::TOP).padding(Padding::horizontal(1)).title(" Press Ctrl+C to Quit "),
        main_layout[2],
    );

    // Horizontal Layout

    let inner_layout = Layout::new(
        Direction::Horizontal,
        [Constraint::Percentage(50), Constraint::Percentage(50)],
    )
    .split(main_layout[1]);

    // Message log

    let messages: Vec<ListItem> = app
        .bus_messages
        .iter()
        .enumerate()
        .map(|(_i, m)| {
            let content = vec![Line::from(Span::raw(format!("{}", m)))];
            ListItem::new(content)
        })
        .rev()
        .collect();

    frame.render_widget(
        List::new(messages).direction(ListDirection::BottomToTop).block(Block::bordered().padding(Padding::horizontal(1)).title(" Message Log ")),
        inner_layout[1],
    );

    // Left Layout

    let vertical_layout = Layout::new(
        Direction::Vertical,
        [Constraint::Length(if app.devices.len() == 0 {3} else {(2 + app.devices.len()) as u16}), Constraint::Min(0)],
    )
    .split(inner_layout[0]);

    // Connected Devices

    if app.devices.len() == 0 {
        frame.render_widget(
            Paragraph::new("No devices connected").block(Block::bordered().padding(Padding::horizontal(1)).title(" Connected devices ")),
            vertical_layout[0],
        );
    } else {
        frame.render_widget(
            Paragraph::new({
                let mut device_list = "".to_string();

                for i in 0..app.devices.len() {
                    device_list += &(format!("#{} : Playdate {}\n", i + 1, (app.devices[i]).0)).to_string();
                }

                device_list
            }).block(Block::bordered().padding(Padding::horizontal(1)).title(" Connected devices ")),
            vertical_layout[0],
        );
    }

    // Server terminal

    let server_terminal_layout = Layout::new(
        Direction::Vertical,
        [Constraint::Min(0), Constraint::Length(2)],
    )
    .split(vertical_layout[1]);

    let messages: Vec<ListItem> = app
        .messages
        .iter()
        .enumerate()
        .map(|(_i, m)| {
            let content = vec![Line::from(Span::raw(format!("{}", m)))];
            ListItem::new(content)
        })
        .rev()
        .collect();

    frame.render_widget(
        List::new(messages).direction(ListDirection::BottomToTop).block(Block::bordered().padding(Padding::horizontal(1)).borders(Borders::LEFT | Borders::RIGHT | Borders::TOP).title(" Server Terminal ")),
        server_terminal_layout[0],
    );

    let width = server_terminal_layout[1].width.max(3) - 3; // keep 2 for borders and 1 for cursor

    let scroll = app.input.visual_scroll(width as usize);
    let input = Paragraph::new(app.input.value())
        .style(Style::default())
        .scroll((0, scroll as u16))
        .block(Block::default().borders(Borders::ALL).title("Input"));

    frame.render_widget(input.block(Block::bordered().padding(Padding::horizontal(1)).borders(Borders::LEFT | Borders::RIGHT | Borders::BOTTOM)), server_terminal_layout[1]);

    frame.set_cursor(
        // Put cursor past the end of the input text
        server_terminal_layout[1].x
            + ((app.input.visual_cursor()).max(scroll) - scroll) as u16
            + 2,
        // Move one line down, from the border to the input line
        server_terminal_layout[1].y,
    );
}